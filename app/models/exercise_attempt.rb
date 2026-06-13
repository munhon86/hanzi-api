class ExerciseAttempt < ApplicationRecord
  belongs_to :user

  validates :difficulty, :exercise_type, :exercise_id, presence: true
  validates :exercise_index, numericality: { greater_than_or_equal_to: 0 }
end
