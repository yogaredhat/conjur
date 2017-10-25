class AuthenticateController < ApplicationController
  include TokenGenerator

  # Request path indicates the username for +authenticate+.
  # The specified role must always exist.
  before_filter :role_lookup
  # Load the authentication provider and check credentials.
  before_filter :perform_authentication

  def authenticate
    render json: authentication_token
  end

  protected

  def authentication_token
    sign_token @role
  end

  def provider
    Provider::Authentication::Basic.new(@role, request)
  end
  
  def perform_authentication
    provider.perform_authentication
  end
  
  def role_lookup
    roleid = Role.roleid_from_username(account, params[:id])
    @role = Role[roleid].tap do |role|
      unless role
        logger.debug "Role #{roleid.inspect} does not exist"
        raise Unauthorized 
      end
    end
  end
end
