module Writing
  # POST /writing/corrections
  # Student submits a short piece of writing; Claude returns a corrected version,
  # per-issue feedback, a score, and a list of weak characters/words to review.
  class CorrectionsController < ApplicationController
    KIND = "writing_correction".freeze

    def create
      return if enforce_daily_limit!(KIND) == false

      text = params[:text].to_s.strip
      return render(json: { error: "text is required" }, status: :unprocessable_entity) if text.blank?

      prompt = params[:prompt].to_s
      known = Array(params[:knownWords]).join(" ")

      system = <<~SYS
        You are a supportive Mandarin Chinese writing tutor for an absolute beginner.
        The learner only knows these words/characters: #{known.presence || '(very limited beginner set)'}.
        Correct their short writing. Prefer corrections that stay within or just barely extend
        their known set. Be encouraging and concise. Respond with ONLY a JSON object, no prose,
        in exactly this shape:
        {
          "corrected": "the corrected Chinese text",
          "feedback": "1-2 sentences of encouraging overall feedback in English",
          "score": 0-100 integer,
          "issues": [
            {"type":"grammar|word-choice|character|unnatural","original":"...","suggestion":"...","explanation":"short English explanation"}
          ],
          "weak_items": ["单","字"]
        }
        weak_items are individual Chinese characters or words the learner got wrong and should review.

        Scoring rubric (be encouraging — this is an absolute beginner):
        - Start from 100 and deduct only for real mistakes.
        - Punctuation (e.g. a missing 。) or other tiny polish issues: deduct at most 3 points each.
        - Word-choice or unnatural phrasing that is still understandable: deduct 5-10 each.
        - A grammar error that changes meaning or a wrong/missing character: deduct 10-15 each.
        - A sentence that is correct and natural for a beginner should score 95-100.
        - Never score below 50 unless the writing is largely incomprehensible or off-topic.
        Keep the score consistent with the issues you list: few/minor issues must mean a high score.
      SYS

      user = "Prompt: #{prompt}\n\nLearner's writing:\n#{text}"

      data, raw = ClaudeClient.new.json(system: system, user: user, max_tokens: 1024)
      AiGeneration.create!(device_id: device_id, kind: KIND, model: ClaudeClient::DEFAULT_MODEL, prompt: user, raw_output: raw)

      render json: {
        corrected: data["corrected"].to_s,
        feedback: data["feedback"].to_s,
        score: data["score"].to_i,
        issues: Array(data["issues"]),
        weak_items: Array(data["weak_items"])
      }
    end
  end
end
