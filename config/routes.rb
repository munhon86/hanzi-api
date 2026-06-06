Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # V0 AI endpoints (no auth; rate-limited per device id).
  post "writing/corrections", to: "writing/corrections#create"
  post "explanations", to: "explanations#create"
  post "exercise_answers", to: "exercises/answers#create"
end
