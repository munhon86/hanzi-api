class CreateRefreshTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      # Only the SHA-256 digest of the raw token is stored; the raw token is shown once.
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at
      # Self-reference: the rotated-to token that replaced this one (reuse detection).
      t.references :replaced_by, foreign_key: { to_table: :refresh_tokens }, null: true

      t.timestamps
    end

    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, :expires_at
  end
end
