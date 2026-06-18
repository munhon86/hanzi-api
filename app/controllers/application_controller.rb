require "jwt" # `JWT::DecodeError` is referenced below; don't rely on autoload ordering.

class ApplicationController < ActionController::API
  rescue_from ClaudeClient::Error, with: :render_ai_error
  rescue_from OpenaiAudioClient::Error, with: :render_ai_error
  rescue_from JWT::DecodeError, with: :render_unauthorized

  # Every endpoint requires a valid Bearer access token by default. Public auth
  # endpoints (sign up / in, token refresh, provider login) opt out with
  # `skip_before_action :authenticate_user!`.
  before_action :authenticate_user!

  attr_reader :current_user

  private

  # Decode the Bearer access token into the current user, or render 401.
  def authenticate_user!
    payload = AuthToken.decode(bearer_token)
    @current_user = User.find_by(id: payload["sub"])
    render_unauthorized unless @current_user
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    scheme, token = header.split(" ", 2)
    return token if scheme == "Bearer" && token.present?

    raise JWT::DecodeError, "missing bearer token"
  end

  def render_unauthorized(_error = nil)
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  # A per-install device id, still sent by the app. Used for daily AI rate-limiting
  # and as the key for one-time device→account migration. Falls back to the remote IP.
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

  # Shared serializer for the authenticated user, matching the shape the client's
  # auth store and Profile screen expect.
  def user_json(user = current_user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      current_difficulty: user.current_difficulty
    }
  end
end
