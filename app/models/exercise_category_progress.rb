class ExerciseCategoryProgress < ApplicationRecord
  belongs_to :user

  validates :difficulty, :exercise_type, presence: true
  validates :current_index, :completed_count, :resume_index, numericality: { greater_than_or_equal_to: 0 }
  validates :exercise_type, uniqueness: { scope: [ :user_id, :difficulty ] }
end
