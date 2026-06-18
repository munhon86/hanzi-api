require "rails_helper"

RSpec.describe "Auth::Sessions", type: :request do
  let!(:user) { create(:user, email: "li@hanzi.local", password: "password123") }

  it "signs in with valid credentials" do
    post "/auth/sign_in", params: { email: "li@hanzi.local", password: "password123" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["token"]).to be_present
    expect(response.parsed_body["refresh_token"]).to be_present
  end

  it "rejects wrong credentials" do
    post "/auth/sign_in", params: { email: "li@hanzi.local", password: "nope" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "signs out by revoking the supplied refresh token" do
    _record, raw = RefreshToken.issue!(user)

    delete "/auth/sign_out", params: { refresh_token: raw }, headers: auth_headers(user)

    expect(response).to have_http_status(:no_content)
    expect(RefreshToken.find_active(raw).active?).to be(false)
  end

  it "requires authentication to sign out" do
    delete "/auth/sign_out", params: { refresh_token: "anything" }
    expect(response).to have_http_status(:unauthorized)
  end
end
