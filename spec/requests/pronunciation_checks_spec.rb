require "rails_helper"

RSpec.describe "PronunciationChecks", type: :request do
  let(:device_id) { "device-pronunciation" }
  let(:headers) { { "X-Device-Id" => device_id } }
  let(:audio) { fixture_file_upload("sample.m4a", "audio/m4a") }

  let(:claude_payload) do
    {
      "score" => 88,
      "verdict" => "Great",
      "feedback" => "The sentence was recognized clearly. Keep the fourth tone in 会 crisp.",
      "words" => [
        { "text" => "他们", "pinyin" => "tā men", "score" => 92, "feedback" => "Clear." }
      ]
    }
  end

  before do
    allow_any_instance_of(OpenaiAudioClient).to receive(:transcribe).and_return("他们会唱歌。")
    allow_any_instance_of(ClaudeClient).to receive(:json).and_return([ claude_payload, claude_payload.to_json ])
  end

  def post_check(params = {})
    post "/pronunciation_checks",
         params: {
           exercise_id: "guided-18",
           target_text: "他们会唱歌。",
           target_pinyin: "tā men huì chàng gē",
           audio: audio
         }.merge(params),
         headers: headers
  end

  it "returns score, verdict, feedback, word feedback, and transcript" do
    post_check

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["score"]).to eq(88)
    expect(body["verdict"]).to eq("Great")
    expect(body["feedback"]).to be_present
    expect(body["words"].first["text"]).to eq("他们")
    expect(body["transcript"]).to eq("他们会唱歌。")
  end

  it "records an AiGeneration audit row" do
    expect { post_check }.to change(AiGeneration, :count).by(1)
    expect(AiGeneration.last.kind).to eq("pronunciation_check")
  end

  it "rejects missing audio" do
    post_check(audio: nil)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["error"]).to eq("audio is required")
  end

  it "returns 429 once the daily limit is exceeded" do
    limit = UsageCounter.limit_for("pronunciation_check")
    limit.times { post_check }

    post_check
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body).to include("error", "reset_at")
  end
end
