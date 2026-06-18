require "jwt"

# Issues and verifies the app's own short-lived ACCESS token (HS256). This is the only
# place signing happens — to move to RS256/AWS KMS later, change just this file.
#
# Refresh tokens are opaque random strings (see RefreshToken), not JWTs.
module AuthToken
  ALGORITHM = "HS256".freeze
  ACCESS_TTL = (ENV["ACCESS_TOKEN_TTL_MINUTES"].presence&.to_i || 45).minutes

  class << self
    def secret
      ENV["AUTH_JWT_SECRET"].presence || Rails.application.secret_key_base
    end

    def encode(user, ttl: ACCESS_TTL)
      now = Time.current.to_i
      payload = {
        sub: user.id,
        iat: now,
        exp: now + ttl.to_i,
        type: "access"
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Returns the decoded payload hash, or raises JWT::DecodeError (incl. expiry) on
    # any invalid/expired/wrong-type token.
    def decode(token)
      payload, = JWT.decode(token, secret, true, algorithm: ALGORITHM, verify_expiration: true)
      raise JWT::DecodeError, "wrong token type" unless payload["type"] == "access"

      payload
    end
  end
end
