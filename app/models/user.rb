class User < ApplicationRecord
  has_many :exercise_category_progresses, dependent: :destroy
  has_many :exercise_attempts, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :current_difficulty, presence: true
end
