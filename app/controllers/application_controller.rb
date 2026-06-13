class ApplicationController < ActionController::API
  rescue_from ClaudeClient::Error, with: :render_ai_error
  rescue_from OpenaiAudioClient::Error, with: :render_ai_error

  private

  # V0 has no auth — a per-install device id (sent by the app) identifies the client
  # for daily rate-limiting. Falls back to the remote IP if the header is missing.
  def device_id
    request.headers["X-Device-Id"].presence || request.remote_ip
  end

  # Enforce a per-device daily limit for an AI action; render 429 when exceeded.
  def enforce_daily_limit!(kind)
    used = UsageCounter.bump!(device_id: device_id, kind: kind)
    limit = UsageCounter.limit_for(kind)
    return if used <= limit

    render json: {
      error: "Daily limit reached for #{kind.tr('_', ' ')}.",
      reset_at: Time.current.end_of_day.iso8601
    }, status: :too_many_requests
    false
  end

  def render_ai_error(error)
    render json: { error: "AI service error: #{error.message}" }, status: :bad_gateway
  end

  def current_user
    @current_user ||= begin
      User.find_by(id: request.headers["X-User-Id"].presence) ||
        User.find_by(device_id: device_id) ||
        User.find_or_create_by!(email: "test@hanzi.local") do |user|
          user.name = "Hanzi Test User"
          user.device_id = "test-device"
          user.current_difficulty = "beginner"
        end
    end
  end
end
