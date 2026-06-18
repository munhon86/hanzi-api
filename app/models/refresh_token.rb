require "digest"
require "securerandom"

# A rotating refresh token. We store only the SHA-256 digest of the raw token; the
# raw value is returned to the client exactly once (at issue/rotation time).
class RefreshToken < ApplicationRecord
  TTL = (ENV["REFRESH_TOKEN_TTL_DAYS"].presence&.to_i || 30).days

  belongs_to :user
  belongs_to :replaced_by, class_name: "RefreshToken", optional: true

  def self.digest(raw) = Digest::SHA256.hexdigest(raw)

  # Issue a new refresh token for a user. Returns [record, raw_token]; only the
  # digest is persisted.
  def self.issue!(user)
    raw = SecureRandom.urlsafe_base64(64)
    record = create!(user: user, token_digest: digest(raw), expires_at: TTL.from_now)
    [ record, raw ]
  end

  def self.find_active(raw)
    find_by(token_digest: digest(raw))
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!(replacement: nil)
    update!(revoked_at: Time.current, replaced_by: replacement)
  end
end
