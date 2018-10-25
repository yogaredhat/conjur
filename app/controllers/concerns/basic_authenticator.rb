# frozen_string_literal: true

module BasicAuthenticator
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Basic::ControllerMethods

  def perform_basic_authn
    # we need to check the auth method.
    # authenticate_with_http_basic doesn't do that and freaks out randomly.
    return unless request.authorization =~ /^Basic /

    authenticate_with_http_basic do |username, password|
      authenticator_login(username, password).tap do |response|
        authentication.authenticated_role = ::Role[response.role_id]
        authentication.basic_user = true
      end
    rescue ::Authentication::Strategy::InvalidCredentials
      raise ApplicationController::Unauthorized, "Invalid username or password"
    rescue ::Authentication::Strategy::InvalidOrigin
      raise ApplicationController::Forbidden, "User is not authorized to login from the current origin"
    rescue ::Authentication::Security::NotAuthorizedInConjur
      raise ApplicationController::Forbidden, "User is not authorized to login to Conjur"
    end
  end

  private

  def authenticator_login(username, password)
    authentication_strategy.login(login_input(username, password))
  end

  def authentication_strategy
    @authentication_strategy ||= ::Authentication::Strategy.new(
      authenticators: installed_login_authenticators,
      audit_log: ::Authentication::AuditLog,
      security: nil,
      env: ENV,
      role_cls: ::Role,
      token_factory: TokenFactory.new,
      oidc_client_class: ::Authentication::AuthnOidc::OidcClient
    )
  end

  def login_input(username, password)
    ::Authentication::Strategy::Input.new(
      authenticator_name: params[:authenticator],
      service_id:         params[:service_id],
      account:            params[:account],
      username:           username,
      password:           password,
      origin:             request.ip,
      request:            request
    )
  end

  def installed_login_authenticators
    @installed_login_authenticators ||= ::Authentication::InstalledAuthenticators.login_authenticators(ENV)
  end
end
