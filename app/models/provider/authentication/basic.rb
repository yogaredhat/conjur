module Provider
  module Authentication
    Basic = Struct.new(:role, :request) do
      def perform_authentication
        api_key = request.body.read
        credentials = role.credentials
        if credentials.blank?
          Rails.logger.debug "No credentials for role #{role.role_id.inspect}"
          raise Exceptions::Unauthorized
        elsif !credentials.valid_api_key?(api_key)
          Rails.logger.debug "User-provided API key does not match"
          raise Exceptions::Unauthorized
        end
        true
      end
    end
  end
end
