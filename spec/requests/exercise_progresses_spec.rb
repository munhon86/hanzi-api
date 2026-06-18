require "rails_helper"

RSpec.describe "ExerciseProgresses", type: :request do
  let!(:user) { create(:user, email: "test@hanzi.local", name: "Hanzi Test User") }

  it "returns one progress row per exercise category" do
    get "/exercise_progresses", params: { difficulty: "beginner" }, headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["user"]["email"]).to eq("test@hanzi.local")
    expect(body["progress"].map { |p| p["exercise_type"] }).to include("reorder_words", "fill_blank")
  end

  it "requires authentication" do
    get "/exercise_progresses", params: { difficulty: "beginner" }
    expect(response).to have_http_status(:unauthorized)
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
         },
         headers: auth_headers(user)

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
         },
         headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["progress"]["current_index"]).to eq(0)
    expect(body["progress"]["completed_count"]).to eq(0)
    expect(body["progress"]["resume_index"]).to eq(2)
    expect(body["progress"]["resume_exercise_id"]).to eq("g-ro-2")
    expect(ExerciseAttempt.count).to eq(0)
  end

  it "keeps progress separate per user and exercise category" do
    other = create(:user, email: "other@hanzi.local", name: "Other")

    post "/exercise_progresses",
         params: {
           difficulty: "beginner", exercise_type: "reorder_words", exercise_id: "g-ro-4",
           exercise_index: 4, correct: true, revealed_answer: false
         },
         headers: auth_headers(user)

    post "/exercise_progresses",
         params: {
           difficulty: "beginner", exercise_type: "fill_blank", exercise_id: "g-fb-1",
           exercise_index: 1, correct: true, revealed_answer: false
         },
         headers: auth_headers(user)

    post "/exercise_progresses",
         params: {
           difficulty: "beginner", exercise_type: "reorder_words", exercise_id: "g-ro-0",
           exercise_index: 0, correct: true, revealed_answer: false
         },
         headers: auth_headers(other)

    get "/exercise_progresses", params: { difficulty: "beginner" }, headers: auth_headers(user)
    user_rows = response.parsed_body["progress"].index_by { |row| row["exercise_type"] }

    expect(user_rows["reorder_words"]["current_index"]).to eq(5)
    expect(user_rows["fill_blank"]["current_index"]).to eq(2)

    get "/exercise_progresses", params: { difficulty: "beginner" }, headers: auth_headers(other)
    other_rows = response.parsed_body["progress"].index_by { |row| row["exercise_type"] }

    expect(other_rows["reorder_words"]["current_index"]).to eq(1)
    expect(other_rows["fill_blank"]["current_index"]).to eq(0)
  end
end
