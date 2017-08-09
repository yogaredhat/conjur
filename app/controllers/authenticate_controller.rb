class AuthenticateController < ApplicationController
  include TokenGenerator
  include HasProviders

  # Request path indicates the username for +authenticate+.
  # The specified role must always exist.
  before_filter :role_lookup
  # Load the authentication provider and check credentials.
  before_filter :perform_authentication

  def authenticate_basic
    render json: authentication_token
  end

  def authenticate_kubernetes
    # TODO: issue a longer-lived token here.
    render json: authentication_token
  end
  
  protected

  def authentication_token
    sign_token @role
  end

  def provider
    lookup_provider(Provider::Authentication).new @role, request
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
