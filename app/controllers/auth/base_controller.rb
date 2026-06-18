module Auth
  # Base for PUBLIC auth endpoints (sign up / in, refresh, provider login) — these run
  # before the user has an access token, so they opt out of `authenticate_user!`.
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!

    private

    # Standard success body for every sign-in path: a fresh access token, a new
    # refresh token (raw, shown once), and the user.
    def render_tokens(user, status: :ok)
      _record, raw_refresh = RefreshToken.issue!(user)
      render json: {
        token: AuthToken.encode(user),
        refresh_token: raw_refresh,
        user: user_json(user)
      }, status: status
    end
  end
end
