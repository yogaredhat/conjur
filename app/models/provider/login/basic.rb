module Provider
  module Login
    Basic = Struct.new(:account, :authentication, :request) do

      require 'action_controller/metal/http_authentication'

      def perform_login
        ActionController::HttpAuthentication::Basic.authenticate(request) do |username, password|
          credentials = Credentials[Role.roleid_from_username(account, username)]
          if credentials && credentials.authenticate(password)
            authentication.authenticated_role = credentials.role
            authentication.basic_user = true
          end
        end
        Rails.logger.debug "Client not authenticated"
        raise Exceptions::Unauthorized unless authentication.authenticated?
        true
      end
    end
  end
end
