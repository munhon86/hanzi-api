class CreateAiGenerations < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_generations do |t|
      t.string :device_id
      t.string :kind, null: false
      t.string :model
      t.text :prompt
      t.text :raw_output

      t.timestamps
    end

    add_index :ai_generations, :kind
  end
end
