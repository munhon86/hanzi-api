require "rails_helper"

RSpec.describe "Me", type: :request do
  let!(:user) { create(:user, email: "me@hanzi.local", name: "Me") }

  it "returns the authenticated user" do
    get "/me", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["user"]).to include(
      "id" => user.id, "email" => "me@hanzi.local", "name" => "Me", "current_difficulty" => "elementary"
    )
  end

  it "returns 401 without a token" do
    get "/me"
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 with a malformed token" do
    get "/me", headers: { "Authorization" => "Bearer not.a.jwt" }
    expect(response).to have_http_status(:unauthorized)
  end
end
