module Auth
  # Rotating refresh: exchange a valid refresh token for a new access + refresh pair.
  class TokensController < BaseController
    def refresh
      raw = params[:refresh_token].to_s
      token = RefreshToken.find_active(raw)
      return render_invalid if token.nil?

      # Reuse detection: a token that was already rotated away (revoked) being
      # presented again suggests theft — revoke the whole family for that user.
      if token.revoked_at.present?
        token.user.refresh_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
        return render_invalid
      end

      return render_invalid unless token.active?

      user = token.user
      new_raw = nil
      RefreshToken.transaction do
        new_record, new_raw = RefreshToken.issue!(user)
        token.revoke!(replacement: new_record)
      end

      render json: {
        token: AuthToken.encode(user),
        refresh_token: new_raw,
        user: user_json(user)
      }, status: :ok
    end

    private

    def render_invalid
      render json: { error: "Invalid refresh token." }, status: :unauthorized
    end
  end
end
