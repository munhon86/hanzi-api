# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_06_10_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ai_generations", force: :cascade do |t|
    t.string "device_id"
    t.string "kind", null: false
    t.string "model"
    t.text "prompt"
    t.text "raw_output"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_ai_generations_on_kind"
  end

  create_table "exercise_attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "difficulty", null: false
    t.string "exercise_type", null: false
    t.string "exercise_id", null: false
    t.integer "exercise_index", null: false
    t.boolean "correct", default: false, null: false
    t.boolean "revealed_answer", default: false, null: false
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_exercise_attempts_on_exercise_id"
    t.index ["user_id", "difficulty", "exercise_type"], name: "idx_on_user_id_difficulty_exercise_type_6ae637338d"
    t.index ["user_id"], name: "index_exercise_attempts_on_user_id"
  end

  create_table "exercise_category_progresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "difficulty", null: false
    t.string "exercise_type", null: false
    t.integer "current_index", default: 0, null: false
    t.integer "completed_count", default: 0, null: false
    t.string "last_exercise_id"
    t.datetime "last_practiced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "resume_index", default: 0, null: false
    t.string "resume_exercise_id"
    t.index ["user_id", "difficulty", "exercise_type"], name: "idx_exercise_progress_user_difficulty_type", unique: true
    t.index ["user_id"], name: "index_exercise_category_progresses_on_user_id"
  end

  create_table "usage_counters", force: :cascade do |t|
    t.string "device_id", null: false
    t.date "day", null: false
    t.string "kind", null: false
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "day", "kind"], name: "index_usage_counters_on_device_id_and_day_and_kind", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "device_id"
    t.string "current_difficulty", default: "beginner", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_users_on_device_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "exercise_attempts", "users"
  add_foreign_key "exercise_category_progresses", "users"
end
