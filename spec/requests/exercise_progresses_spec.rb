require "rails_helper"

RSpec.describe "ExerciseProgresses", type: :request do
  before { User.destroy_all }

  let!(:user) { User.create!(email: "test@hanzi.local", name: "Hanzi Test User") }

  it "returns one progress row per exercise category" do
    get "/exercise_progresses", params: { difficulty: "beginner" }

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["user"]["email"]).to eq("test@hanzi.local")
    expect(body["progress"].map { |p| p["exercise_type"] }).to include("reorder_words", "fill_blank")
  end

  it "records an attempt and advances the category position" do
    post "/exercise_progresses",
         params: {
           difficulty: "beginner",
           exercise_type: "reorder_words",
           exercise_id: "g-ro-1",
           exercise_index: 4,
           correct: true,
           revealed_answer: false,
           score: 100
         }

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["progress"]["current_index"]).to eq(5)
    expect(body["progress"]["resume_index"]).to eq(5)
    expect(body["progress"]["resume_exercise_id"]).to be_nil
    expect(ExerciseAttempt.last.exercise_id).to eq("g-ro-1")
  end

  it "saves the current resume position without creating an attempt" do
    post "/exercise_progresses/resume",
         params: {
           difficulty: "beginner",
           exercise_type: "reorder_words",
           exercise_id: "g-ro-2",
           exercise_index: 2
         }

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["progress"]["current_index"]).to eq(0)
    expect(body["progress"]["completed_count"]).to eq(0)
    expect(body["progress"]["resume_index"]).to eq(2)
    expect(body["progress"]["resume_exercise_id"]).to eq("g-ro-2")
    expect(ExerciseAttempt.count).to eq(0)
  end

  it "keeps progress separate per user and exercise category" do
    User.create!(email: "other@hanzi.local", name: "Other", device_id: "other-device")

    post "/exercise_progresses",
         params: {
           difficulty: "beginner",
           exercise_type: "reorder_words",
           exercise_id: "g-ro-4",
           exercise_index: 4,
           correct: true,
           revealed_answer: false
         }

    post "/exercise_progresses",
         params: {
           difficulty: "beginner",
           exercise_type: "fill_blank",
           exercise_id: "g-fb-1",
           exercise_index: 1,
           correct: true,
           revealed_answer: false
         }

    post "/exercise_progresses",
         headers: { "X-Device-Id" => "other-device" },
         params: {
           difficulty: "beginner",
           exercise_type: "reorder_words",
           exercise_id: "g-ro-0",
           exercise_index: 0,
           correct: true,
           revealed_answer: false
         }

    get "/exercise_progresses", params: { difficulty: "beginner" }
    test_user_rows = response.parsed_body["progress"].index_by { |row| row["exercise_type"] }

    expect(test_user_rows["reorder_words"]["current_index"]).to eq(5)
    expect(test_user_rows["fill_blank"]["current_index"]).to eq(2)

    get "/exercise_progresses", headers: { "X-Device-Id" => "other-device" }, params: { difficulty: "beginner" }
    other_user_rows = response.parsed_body["progress"].index_by { |row| row["exercise_type"] }

    expect(other_user_rows["reorder_words"]["current_index"]).to eq(1)
    expect(other_user_rows["fill_blank"]["current_index"]).to eq(0)
  end
end
