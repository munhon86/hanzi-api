require "rails_helper"

RSpec.describe "Exercises::Answers", type: :request do
  let!(:user) { create(:user) }
  let(:device_id) { "device-xyz" }
  let(:headers) do
    { "X-Device-Id" => device_id, "CONTENT_TYPE" => "application/json", "Authorization" => "Bearer #{AuthToken.encode(user)}" }
  end

  let(:claude_payload) do
    {
      "acceptable" => true,
      "score" => 90,
      "feedback" => "Nice — that's a correct, natural sentence.",
      "issues" => [
        { "type" => "punctuation", "original" => "我喝水", "correction" => "我喝水。", "explanation" => "End with 。" }
      ],
      "weak_items" => [],
      "sample_answers" => [ "我喝水。" ]
    }
  end

  before do
    allow_any_instance_of(ClaudeClient).to receive(:json).and_return([ claude_payload, claude_payload.to_json ])
  end

  def post_answer(answer: "我喝水。")
    post "/exercise_answers",
         params: {
           exercise_type: "word_bank",
           prompt: "Use the words to write a sentence about the picture.",
           given_words: %w[我 喝 水],
           grammar_focus: "subject + verb + object",
           sample_answers: [ "我喝水。" ],
           answer: answer,
           knownWords: %w[我 喝 水]
         }.to_json,
         headers: headers
  end

  it "returns acceptability, score, feedback, and sample answers" do
    post_answer

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["acceptable"]).to be(true)
    expect(body["score"]).to eq(90)
    expect(body["feedback"]).to be_present
    expect(body["sample_answers"]).to eq([ "我喝水。" ])
    expect(body["issues"].first["correction"]).to eq("我喝水。")
  end

  it "records an AiGeneration audit row" do
    expect { post_answer }.to change(AiGeneration, :count).by(1)
    expect(AiGeneration.last.kind).to eq("exercise_answer")
  end

  it "rejects a blank answer" do
    post_answer(answer: "   ")
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "returns 429 once the daily limit is exceeded" do
    limit = UsageCounter.limit_for("exercise_answer")
    limit.times { post_answer }

    post_answer
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body).to include("error", "reset_at")
  end
end
