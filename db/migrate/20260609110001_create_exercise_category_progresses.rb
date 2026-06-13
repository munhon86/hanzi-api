class CreateExerciseCategoryProgresses < ActiveRecord::Migration[7.2]
  def change
    create_table :exercise_category_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :difficulty, null: false
      t.string :exercise_type, null: false
      t.integer :current_index, null: false, default: 0
      t.integer :completed_count, null: false, default: 0
      t.string :last_exercise_id
      t.datetime :last_practiced_at

      t.timestamps
    end

    add_index :exercise_category_progresses,
              [ :user_id, :difficulty, :exercise_type ],
              unique: true,
              name: "idx_exercise_progress_user_difficulty_type"
  end
end
