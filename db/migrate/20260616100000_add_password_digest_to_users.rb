class AddPasswordDigestToUsers < ActiveRecord::Migration[7.2]
  def change
    # Nullable: SSO-only users (Google/Apple) never set a password.
    add_column :users, :password_digest, :string, null: true
  end
end
