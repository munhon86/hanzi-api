FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@hanzi.local" }
    name { "Test User" }
    current_difficulty { "elementary" }
    password { "password123" }
  end
end
