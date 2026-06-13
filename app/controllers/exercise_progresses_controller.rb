class ExerciseProgressesController < ApplicationController
  TYPES = %w[reorder_words fill_blank match_sentence word_bank arrange_sentences write_sentence].freeze
  DIFFICULTIES = %w[beginner elementary intermediate advanced].freeze

  def index
    difficulty = normalized_difficulty
    progresses = TYPES.map do |type|
      progress = progress_for(difficulty, type)
      serialize(progress)
    end

    render json: { user: user_json, progress: progresses }
  end

  def user_json
    {
      id: current_user.id,
      email: current_user.email,
      name: current_user.name,
      current_difficulty: current_user.current_difficulty
    }
  end

  def create
    difficulty = normalized_difficulty
    type = params.require(:exercise_type).to_s
    return render(json: { error: "unknown exercise_type" }, status: :unprocessable_entity) unless TYPES.include?(type)

    index = params.require(:exercise_index).to_i
    correct = ActiveModel::Type::Boolean.new.cast(params[:correct])
    revealed = ActiveModel::Type::Boolean.new.cast(params[:revealed_answer])
    exercise_id = params.require(:exercise_id).to_s

    attempt = current_user.exercise_attempts.create!(
      difficulty: difficulty,
      exercise_type: type,
      exercise_id: exercise_id,
      exercise_index: index,
      correct: correct,
      revealed_answer: revealed,
      score: params[:score]
    )

    progress = progress_for(difficulty, type)
    progress.update!(
      current_index: [ progress.current_index, index + 1 ].max,
      completed_count: progress.completed_count + (correct || revealed ? 1 : 0),
      resume_index: index + 1,
      resume_exercise_id: nil,
      last_exercise_id: exercise_id,
      last_practiced_at: Time.current
    )

    render json: { attempt_id: attempt.id, progress: serialize(progress) }, status: :created
  end

  def resume
    difficulty = normalized_difficulty
    type = params.require(:exercise_type).to_s
    return render(json: { error: "unknown exercise_type" }, status: :unprocessable_entity) unless TYPES.include?(type)

    index = params.require(:exercise_index).to_i
    exercise_id = params.require(:exercise_id).to_s

    progress = progress_for(difficulty, type)
    progress.update!(
      resume_index: index,
      resume_exercise_id: exercise_id,
      last_exercise_id: exercise_id,
      last_practiced_at: Time.current
    )

    render json: { progress: serialize(progress) }, status: :ok
  end

  private

  def normalized_difficulty
    difficulty = params[:difficulty].presence || current_user.current_difficulty
    return difficulty if DIFFICULTIES.include?(difficulty)

    "beginner"
  end

  def progress_for(difficulty, type)
    current_user.exercise_category_progresses.find_or_create_by!(
      difficulty: difficulty,
      exercise_type: type
    )
  end

  def serialize(progress)
    {
      difficulty: progress.difficulty,
      exercise_type: progress.exercise_type,
      current_index: progress.current_index,
      completed_count: progress.completed_count,
      resume_index: progress.resume_index,
      resume_exercise_id: progress.resume_exercise_id,
      last_exercise_id: progress.last_exercise_id,
      last_practiced_at: progress.last_practiced_at&.iso8601
    }
  end
end
