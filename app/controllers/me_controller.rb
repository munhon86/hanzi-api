# Returns the authenticated user (used by the client to bootstrap its auth state).
class MeController < ApplicationController
  def show
    render json: { user: user_json }
  end
end
