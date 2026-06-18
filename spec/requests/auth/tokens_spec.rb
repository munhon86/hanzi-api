require "rails_helper"

RSpec.describe "Auth::Tokens", type: :request do
  let!(:user) { create(:user) }

  it "rotates a valid refresh token into a new pair" do
    _record, raw = RefreshToken.issue!(user)

    post "/auth/refresh", params: { refresh_token: raw }

    expect(response).to have_http_status(:ok)
    new_refresh = response.parsed_body["refresh_token"]
    expect(response.parsed_body["token"]).to be_present
    expect(new_refresh).to be_present
    expect(new_refresh).not_to eq(raw)
    # The old token is now revoked.
    expect(RefreshToken.find_active(raw).active?).to be(false)
    # The new token works.
    expect(RefreshToken.find_active(new_refresh).active?).to be(true)
  end

  it "rejects an unknown refresh token" do
    post "/auth/refresh", params: { refresh_token: "not-a-real-token" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "detects reuse: replaying a rotated token revokes the whole family" do
    _record, raw = RefreshToken.issue!(user)
    post "/auth/refresh", params: { refresh_token: raw } # rotates raw → new
    new_refresh = response.parsed_body["refresh_token"]

    # Replay the already-rotated (revoked) token.
    post "/auth/refresh", params: { refresh_token: raw }
    expect(response).to have_http_status(:unauthorized)

    # The replacement is now revoked too (family invalidated).
    expect(RefreshToken.find_active(new_refresh).active?).to be(false)
    expect(user.refresh_tokens.where(revoked_at: nil)).to be_empty
  end
end
