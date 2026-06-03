class CreateUsageCounters < ActiveRecord::Migration[7.2]
  def change
    create_table :usage_counters do |t|
      t.string :device_id, null: false
      t.date :day, null: false
      t.string :kind, null: false
      t.integer :count, null: false, default: 0

      t.timestamps
    end

    add_index :usage_counters, %i[device_id day kind], unique: true
  end
end
