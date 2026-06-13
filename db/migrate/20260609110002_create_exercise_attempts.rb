class CreateExerciseAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :exercise_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :difficulty, null: false
      t.string :exercise_type, null: false
      t.string :exercise_id, null: false
      t.integer :exercise_index, null: false
      t.boolean :correct, null: false, default: false
      t.boolean :revealed_answer, null: false, default: false
      t.integer :score

      t.timestamps
    end

    add_index :exercise_attempts, [ :user_id, :difficulty, :exercise_type ]
    add_index :exercise_attempts, :exercise_id
  end
end
