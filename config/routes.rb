Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication. Public endpoints issue the app's own access + refresh tokens.
  namespace :auth do
    post   "sign_up",  to: "registrations#create"
    post   "sign_in",  to: "sessions#create"
    delete "sign_out", to: "sessions#destroy"
    post   "refresh",  to: "tokens#refresh"
    # Phase 2: post "migrate", to: "migrations#create"
    # Phase 3: post "google", to: "google#create"
    # Phase 4: post "apple",  to: "apple#create"
  end
  get "me", to: "me#show"

  # AI + progress endpoints (now require a Bearer access token; still rate-limited per device id).
  post "writing/corrections", to: "writing/corrections#create"
  post "explanations", to: "explanations#create"
  post "exercise_answers", to: "exercises/answers#create"
  post "pronunciation_checks", to: "pronunciation_checks#create"
  resources :exercise_progresses, only: [ :index, :create ] do
    post :resume, on: :collection
  end
end
