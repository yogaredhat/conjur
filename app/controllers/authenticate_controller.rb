# NOTE: This is needed to make the introspection use by InstalledAuthenticators
#       work.  It cannot be placed in an initializer instead.  There may be a 
#       better place for it, but this works.
#
#       It's purpose it to load all the pluggable authenticator files into 
#       memory, so we can determine which authenticators are available
#
Dir[File.expand_path("../domain/authentication/**/*.rb", __dir__)].each do |f|
  require f
end

class AuthenticateController < ApplicationController
  def authenticate
    authentication_token = ::Authentication::Strategy.new(
      authenticators: ::Authentication::InstalledAuthenticators.new(ENV),
      security: nil,
      env: ENV,
      token_factory: TokenFactory.new
    ).conjur_token(
      ::Authentication::Strategy::Input.new(
        authenticator_name: authenticator_name,
        password: request.body.read
        role: target_role,
        service: service
      )
    )
    render json: authentication_token
    audit_event.emit_success
  rescue => e
    logger.debug("Authentication Error: #{e.message}")
    audit_event.emit_failure e.message
    raise Unauthorized
  end

  private

  def audit_event
    @audit_event ||= Audit::Event::Authn.new \
      role: target_role,
      authenticator_name: authenticator_name,
      service: service
  end

  def target_role
    @target_role ||= Role.by_login(params[:id], account: account) or raise Unauthorized
  end

  def authenticator_name
    @authenticator_name ||= params[:authenticator]
  end

  def account
    @account ||= params[:account] or raise ArgumentError, 'account required'
  end
  
  def service_name
    [authenticator_name, params[:service_id]].compact.join '/'
  end

  def service
    @service ||= Resource[account, 'webservice'.freeze, service_name]
  end
end
