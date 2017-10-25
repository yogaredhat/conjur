class LoginController < ApplicationController
  include BasicAuthenticator

  # Perform the login strategy.
  before_filter :perform_login

  # Ensure that the referenced role exists.
  before_filter :find_role

  # Ensure the credentials exist if they will be accessed or modified.
  before_filter :ensure_credentials

  def login
    render_api_key
  end

  protected

  def render_api_key
    render text: @role.credentials.api_key
  end

  def perform_login
    Provider::Login::Basic.new(account, authentication, request).perform_login
  end

  def find_role
    raise Unauthorized, "Role not found" unless @role = authentication.apply_to_role
  end
  
  # Ensure that the current role has credentials.
  def ensure_credentials
    @role.credentials ||= Credentials.new(role: @role)
  end
end
