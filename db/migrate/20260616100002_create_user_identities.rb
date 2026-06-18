class CreateUserIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :user_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false # "google" | "apple"
      t.string :provider_uid, null: false # stable subject id from the provider
      t.string :email

      t.timestamps
    end

    # One identity per provider account, and one identity per provider per user.
    add_index :user_identities, [ :provider, :provider_uid ], unique: true
    add_index :user_identities, [ :user_id, :provider ], unique: true
  end
end
