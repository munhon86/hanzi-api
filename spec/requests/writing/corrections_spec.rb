require "rails_helper"

RSpec.describe "Writing::Corrections", type: :request do
  let(:device_id) { "device-abc" }
  let(:headers) { { "X-Device-Id" => device_id, "CONTENT_TYPE" => "application/json" } }

  let(:claude_payload) do
    {
      "corrected" => "我是学生。",
      "feedback" => "Great start! Watch the word order.",
      "score" => 82,
      "issues" => [
        { "type" => "grammar", "original" => "我学生", "suggestion" => "我是学生", "explanation" => "Use 是 to link." }
      ],
      "weak_items" => [ "是" ]
    }
  end

  before do
    allow_any_instance_of(ClaudeClient).to receive(:json).and_return([ claude_payload, claude_payload.to_json ])
  end

  def post_correction(text: "我学生", prompt: "Introduce yourself")
    post "/writing/corrections",
         params: { text: text, prompt: prompt, knownWords: %w[我 是 学生] }.to_json,
         headers: headers
  end

  it "returns the corrected text, score, and weak items" do
    post_correction

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["corrected"]).to eq("我是学生。")
    expect(body["score"]).to eq(82)
    expect(body["weak_items"]).to eq([ "是" ])
    expect(body["issues"].first["type"]).to eq("grammar")
  end

  it "records an AiGeneration audit row" do
    expect { post_correction }.to change(AiGeneration, :count).by(1)
    expect(AiGeneration.last.kind).to eq("writing_correction")
  end

  it "rejects a blank submission" do
    post_correction(text: "  ")
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "returns 429 once the daily limit is exceeded" do
    limit = UsageCounter.limit_for("writing_correction")
    limit.times { post_correction }

    post_correction
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body).to include("error", "reset_at")
  end
end
