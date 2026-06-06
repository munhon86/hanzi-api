module Exercises
  # POST /exercise_answers
  # Checks whether a learner's sentence is an acceptable answer for an open-ended
  # guided exercise (word_bank / write_sentence). More structured than free-form
  # correction: it judges acceptability against the exercise's intent and any
  # given words, and returns a corrected/natural version with per-issue feedback.
  class AnswersController < ApplicationController
    KIND = "exercise_answer".freeze

    def create
      return if enforce_daily_limit!(KIND) == false

      answer = params[:answer].to_s.strip
      return render(json: { error: "answer is required" }, status: :unprocessable_entity) if answer.blank?

      exercise_type = params[:exercise_type].to_s
      prompt = params[:prompt].to_s
      given = Array(params[:given_words]).join(" ")
      grammar = params[:grammar_focus].to_s
      samples = Array(params[:sample_answers]).join(" / ")
      scene = params[:scene_description].to_s
      known = Array(params[:knownWords]).join(" ")

      system = <<~SYS
        You are a supportive Mandarin Chinese writing tutor for an absolute beginner.
        The learner is doing a guided writing exercise of type "#{exercise_type}".
        Exercise instruction: #{prompt.presence || '(write a short correct sentence)'}
        #{scene.present? ? "The picture shows: #{scene}. The answer should describe it." : ''}
        #{given.present? ? "They must use these words: #{given}." : ''}
        #{grammar.present? ? "Grammar focus: #{grammar}." : ''}
        #{samples.present? ? "Example acceptable answers: #{samples}." : ''}
        The learner only knows these words/characters: #{known.presence || '(very limited beginner set)'}.

        Judge whether their answer is an ACCEPTABLE response to this exercise (grammatical,
        on-task, and — if words were given — uses them). Multiple correct phrasings are fine.
        Be encouraging and concise. Respond with ONLY a JSON object, no prose, in exactly this shape:
        {
          "acceptable": true or false,
          "score": 0-100 integer,
          "feedback": "1-2 sentences of encouraging English feedback",
          "issues": [
            {"type":"grammar|word-choice|word-order|character|unnatural|punctuation","original":"...","correction":"...","explanation":"short English explanation"}
          ],
          "weak_items": ["单","字"],
          "sample_answers": ["a natural correct answer"]
        }
        weak_items are individual Chinese characters or words the learner got wrong and should review.

        Scoring rubric (be encouraging — this is an absolute beginner):
        - Start from 100 and deduct only for real mistakes.
        - acceptable=true whenever the answer is on-task and grammatical, even if not identical to the examples.
        - Punctuation (e.g. a missing 。) or tiny polish: deduct at most 3 points each; still acceptable.
        - Word-choice or unnatural phrasing that is understandable: deduct 5-10 each.
        - A grammar error that changes meaning, a wrong/missing character, or not using a required word: deduct 10-15 each and likely acceptable=false.
        - A correct, natural beginner answer scores 95-100.
        Keep the score consistent with acceptable and the issues listed.
      SYS

      user = "Learner's answer:\n#{answer}"

      data, raw = ClaudeClient.new.json(system: system, user: user, max_tokens: 1024)
      AiGeneration.create!(device_id: device_id, kind: KIND, model: ClaudeClient::DEFAULT_MODEL, prompt: user, raw_output: raw)

      render json: {
        acceptable: data["acceptable"] ? true : false,
        score: data["score"].to_i,
        feedback: data["feedback"].to_s,
        issues: Array(data["issues"]),
        weak_items: Array(data["weak_items"]),
        sample_answers: Array(data["sample_answers"])
      }
    end
  end
end
