require "rails_helper"

RSpec.describe "Explanations", type: :request do
  let(:device_id) { "device-xyz" }
  let(:headers) { { "X-Device-Id" => device_id, "CONTENT_TYPE" => "application/json" } }

  let(:claude_payload) do
    {
      "hanzi" => "学生",
      "pinyin" => "xuésheng",
      "meaning" => "student",
      "usage" => "我是学生 means 'I am a student.'"
    }
  end

  before do
    allow_any_instance_of(ClaudeClient).to receive(:json).and_return([ claude_payload, claude_payload.to_json ])
  end

  def post_explanation(text: "学生")
    post "/explanations",
         params: { text: text, knownWords: %w[我 是] }.to_json,
         headers: headers
  end

  it "returns a grounded explanation" do
    post_explanation

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["hanzi"]).to eq("学生")
    expect(body["pinyin"]).to eq("xuésheng")
    expect(body["meaning"]).to eq("student")
    expect(body["usage"]).to be_present
  end

  it "records an AiGeneration audit row" do
    expect { post_explanation }.to change(AiGeneration, :count).by(1)
    expect(AiGeneration.last.kind).to eq("explanation")
  end

  it "rejects a blank submission" do
    post_explanation(text: "")
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "returns 429 once the daily limit is exceeded" do
    limit = UsageCounter.limit_for("explanation")
    limit.times { post_explanation }

    post_explanation
    expect(response).to have_http_status(:too_many_requests)
  end
end
