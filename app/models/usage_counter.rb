class UsageCounter < ApplicationRecord
  # Per-tier daily AI limits for the V0 prototype (no auth/tiers yet — one free tier).
  DAILY_LIMITS = {
    "writing_correction" => 20,
    "explanation" => 60,
    "exercise_answer" => 40
  }.freeze

  validates :device_id, :day, :kind, presence: true

  # Atomically bump today's counter for a device+kind and return the new value.
  def self.bump!(device_id:, kind:)
    counter = find_or_create_by!(device_id: device_id, day: Date.current, kind: kind)
    counter.with_lock do
      counter.increment!(:count)
    end
    counter.count
  end

  def self.limit_for(kind)
    DAILY_LIMITS.fetch(kind, 30)
  end
end
