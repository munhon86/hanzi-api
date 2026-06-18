# Helpers for request specs now that every endpoint requires a Bearer access token.
module AuthHelpers
  # Authorization header for a user, plus a device id (still used for rate-limiting).
  def auth_headers(user, device_id: "test-device")
    {
      "Authorization" => "Bearer #{AuthToken.encode(user)}",
      "X-Device-Id" => device_id
    }
  end
end
