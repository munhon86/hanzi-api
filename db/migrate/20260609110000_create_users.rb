class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.string :device_id
      t.string :current_difficulty, null: false, default: "beginner"

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :device_id
  end
end
