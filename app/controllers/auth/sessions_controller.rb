module Auth
  # Email/password sign in (#create) and sign out (#destroy, revokes a refresh token).
  class SessionsController < BaseController
    # Sign out needs an authenticated user; sign in does not.
    before_action :authenticate_user!, only: :destroy

    def create
      user = User.find_by([ "lower(email) = ?", params[:email].to_s.strip.downcase ])
      if user&.authenticate(params[:password].to_s)
        render_tokens(user)
      else
        render json: { error: "Invalid email or password." }, status: :unauthorized
      end
    end

    # Revoke the supplied refresh token (the access token alone can't identify it).
    # The client clears local credentials regardless of this response.
    def destroy
      raw = params[:refresh_token].to_s
      token = RefreshToken.find_active(raw)
      token.revoke! if token&.user_id == current_user.id && token.active?
      head :no_content
    end
  end
end
