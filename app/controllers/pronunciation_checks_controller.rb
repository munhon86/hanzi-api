# POST /pronunciation_checks
# Accepts a mobile recording, transcribes what the learner said, then returns
# simple Mandarin pronunciation feedback for the target exercise sentence.
class PronunciationChecksController < ApplicationController
  KIND = "pronunciation_check".freeze

  def create
    return if enforce_daily_limit!(KIND) == false

    target_text = params[:target_text].to_s.strip
    target_pinyin = params[:target_pinyin].to_s.strip
    exercise_id = params[:exercise_id].to_s.strip
    audio = params[:audio]

    return render(json: { error: "target_text is required" }, status: :unprocessable_entity) if target_text.blank?
    return render(json: { error: "audio is required" }, status: :unprocessable_entity) if audio.blank?

    transcript = OpenaiAudioClient.new.transcribe(audio)
    data, raw = score_pronunciation(
      exercise_id: exercise_id,
      target_text: target_text,
      target_pinyin: target_pinyin,
      transcript: transcript
    )

    AiGeneration.create!(
      device_id: device_id,
      kind: KIND,
      model: "#{OpenaiAudioClient::DEFAULT_MODEL}+#{ClaudeClient::DEFAULT_MODEL}",
      prompt: "Target: #{target_text}\nPinyin: #{target_pinyin}\nTranscript: #{transcript}",
      raw_output: raw
    )

    render json: {
      score: data["score"].to_i,
      verdict: data["verdict"].to_s.presence || verdict_for(data["score"].to_i),
      feedback: data["feedback"].to_s,
      words: Array(data["words"]),
      transcript: transcript
    }
  end

  private

  def score_pronunciation(exercise_id:, target_text:, target_pinyin:, transcript:)
    system = <<~SYS
      You are a supportive Mandarin pronunciation coach for an absolute beginner.
      The learner attempted to say a target Chinese sentence. OpenAI speech-to-text
      heard the transcript below. Judge how close the spoken attempt appears to be.

      Important limitations:
      - You only have the transcript, not acoustic tone curves.
      - Do not claim perfect tone analysis.
      - Penalize clearly missing, extra, or wrong Chinese words/characters.
      - If the transcript exactly or nearly matches the target, give a high score
        and remind the learner to keep tones clear.

      Respond with ONLY a JSON object, no prose, in exactly this shape:
      {
        "score": 0-100 integer,
        "verdict": "short label such as Great, Almost, Try again",
        "feedback": "1-2 short English sentences with actionable pronunciation advice",
        "words": [
          {"text":"Chinese word or character", "pinyin":"pinyin", "score":0-100, "feedback":"short tip"}
        ]
      }
    SYS

    user = <<~USER
      Exercise id: #{exercise_id.presence || "(unknown)"}
      Target Chinese: #{target_text}
      Target pinyin: #{target_pinyin.presence || "(not provided)"}
      Speech-to-text transcript: #{transcript}
    USER

    ClaudeClient.new.json(system: system, user: user, max_tokens: 768)
  end

  def verdict_for(score)
    return "Great" if score >= 85
    return "Almost" if score >= 65

    "Try again"
  end
end
