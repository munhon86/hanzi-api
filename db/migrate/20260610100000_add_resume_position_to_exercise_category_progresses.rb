class AddResumePositionToExerciseCategoryProgresses < ActiveRecord::Migration[7.2]
  def change
    add_column :exercise_category_progresses, :resume_index, :integer, null: false, default: 0
    add_column :exercise_category_progresses, :resume_exercise_id, :string
  end
end
