module Kubernetes
  class AuthenticateController < ::AuthenticateController
    # Request path indicates the +service_id+
    before_action :service_lookup
    # Ensure that the role has the necessary privilege on the webservice.
    before_action :authorize_role

    protected

    def provider
      Provider::Authentication::Kubernetes.new @role, request
    end

    def authorize_role
      raise AuthenticationError, "#{role.id.inspect} does not have 'authenticate' privilege on #{@service.id.inspect}" unless @role.allowed_to?("authenticate", @service)
    end

    def service_id
      params[:service_id]
    end

    def service_lookup
      id = "#{account}:webservice:conjur/authn-kubernetes/#{service_id}"
      @service ||= Resource[id] or raise RecordNotFound, "#{id.inspect} not found"
    end
  end
end
