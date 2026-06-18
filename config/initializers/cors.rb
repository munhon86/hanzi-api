# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# CORS for the Expo **web** build (native iOS/Android fetch is not subject to CORS).
# Set CORS_ORIGINS to a comma-separated allowlist in production; the defaults cover the
# local Expo web dev server.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(ENV["CORS_ORIGINS"].presence&.split(",")&.map(&:strip) || %w[http://localhost:8081 http://localhost:19006])

    resource "*",
      headers: :any,
      expose: %w[Authorization],
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
