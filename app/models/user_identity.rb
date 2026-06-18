# Links a User to an external identity provider (Google/Apple). A user may have one
# identity per provider; one provider account maps to exactly one user.
class UserIdentity < ApplicationRecord
  PROVIDERS = %w[google apple].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider_uid, presence: true, uniqueness: { scope: :provider }
end
