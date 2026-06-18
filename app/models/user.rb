class User < ApplicationRecord
  # SSO-only users (Google/Apple) have no password, so skip the built-in password
  # presence validation; Auth::RegistrationsController validates it for email sign-up.
  has_secure_password validations: false

  has_many :exercise_category_progresses, dependent: :destroy
  has_many :exercise_attempts, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy
  has_many :user_identities, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :current_difficulty, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }
end
