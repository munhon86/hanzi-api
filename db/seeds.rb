# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Test account for development / manual sign-in (email + password auth).
test_user = User.find_or_initialize_by(email: "test@example.com")
test_user.name = "Test User"
test_user.current_difficulty = "elementary"
test_user.password = "password123"
test_user.save!
puts "Seeded test account: test@example.com / password123"
