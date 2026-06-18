require "rails_helper"

RSpec.describe "Auth::Registrations", type: :request do
  it "creates a user and returns tokens" do
    post "/auth/sign_up", params: { name: "Mei", email: "Mei@Hanzi.local", password: "password123" }

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["token"]).to be_present
    expect(body["refresh_token"]).to be_present
    expect(body["user"]).to include("email" => "mei@hanzi.local", "name" => "Mei")
    expect(User.find_by(email: "mei@hanzi.local")).to be_present
  end

  it "requires a name" do
    post "/auth/sign_up", params: { email: "x@hanzi.local", password: "password123" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(User.count).to eq(0)
  end

  it "rejects a short password" do
    post "/auth/sign_up", params: { name: "X", email: "x@hanzi.local", password: "short" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(User.count).to eq(0)
  end

  it "rejects a duplicate email (case-insensitive)" do
    create(:user, email: "dupe@hanzi.local")
    post "/auth/sign_up", params: { name: "Dupe", email: "DUPE@hanzi.local", password: "password123" }
    expect(response).to have_http_status(:conflict)
  end
end
