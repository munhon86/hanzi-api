module Auth
  # Email/password sign up.
  class RegistrationsController < BaseController
    MIN_PASSWORD_LENGTH = 8

    def create
      email = params[:email].to_s.strip
      password = params[:password].to_s
      name = params[:name].to_s.strip.presence

      if name.nil?
        return render json: { error: "Name is required." }, status: :unprocessable_entity
      end

      if password.length < MIN_PASSWORD_LENGTH
        return render json: { error: "Password must be at least #{MIN_PASSWORD_LENGTH} characters." },
                      status: :unprocessable_entity
      end

      # has_secure_password skips presence validation (validations: false), so guard
      # email uniqueness explicitly to return a clean 409 instead of a 500.
      if User.exists?([ "lower(email) = ?", email.downcase ])
        return render json: { error: "An account with that email already exists." }, status: :conflict
      end

      user = User.new(email: email, name: name, password: password, current_difficulty: "elementary")
      return render json: { error: user.errors.full_messages.to_sentence }, status: :unprocessable_entity unless user.save

      render_tokens(user, status: :created)
    end
  end
end
