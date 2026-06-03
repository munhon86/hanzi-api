# POST /explanations
# Powers tap-to-explain in the story reader: a learner taps a word/sentence and gets a
# short, grounded English explanation (meaning, pinyin, usage) constrained to their level.
class ExplanationsController < ApplicationController
  KIND = "explanation".freeze

  def create
    return if enforce_daily_limit!(KIND) == false

    text = params[:text].to_s.strip
    return render(json: { error: "text is required" }, status: :unprocessable_entity) if text.blank?

    known = Array(params[:knownWords]).join(" ")

    system = <<~SYS
      You are a concise Mandarin Chinese tutor for an absolute beginner.
      The learner only knows these words/characters: #{known.presence || '(very limited beginner set)'}.
      Explain the given Chinese word, character, or short phrase in simple English.
      Keep it short and grounded — do not invent meanings. Respond with ONLY a JSON object,
      no prose, in exactly this shape:
      {
        "hanzi": "the word/character being explained",
        "pinyin": "pinyin with tone marks",
        "meaning": "short English meaning",
        "usage": "1 short sentence on how it is used"
      }
    SYS

    user = "Explain: #{text}"

    data, raw = ClaudeClient.new.json(system: system, user: user, max_tokens: 512)
    AiGeneration.create!(device_id: device_id, kind: KIND, model: ClaudeClient::DEFAULT_MODEL, prompt: user, raw_output: raw)

    render json: {
      hanzi: data["hanzi"].to_s,
      pinyin: data["pinyin"].to_s,
      meaning: data["meaning"].to_s,
      usage: data["usage"].to_s
    }
  end
end
