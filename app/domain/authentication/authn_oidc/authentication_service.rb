require 'uri'
require 'openid_connect'

module Authentication
  module AuthnOidc
    class AuthenticationService
      attr_reader :service_id
      attr_reader :conjur_account

      # Constructs AuthenticationService from the <service-id>, which is typically something like
      # conjur/authn-oidc/<service-id>.
      def initialize(service_id, conjur_account)
        @service_id = service_id
        @conjur_account = conjur_account
      end

      # Retrieves an id token from the OpenIDConnect Provider and returns it decoded
      def user_details(request_body)

        begin
        file = File.open("/src/motic_user_details", "w")
        file.write("__X__")

file.write("Z1")
file.write(request_body)
file.write("Z1")
        request_body = URI.decode_www_form(request_body)
file.write("Z2")
        @redirect_uri = request_body.assoc('redirect_uri').last
file.write("Z3")
        authorization_code = request_body.assoc('code').last
file.write("Z4")


file.write("\n\n\nidentifier: #{client_id}")
file.write("\n\n\nsecret: #{client_secret}")
file.write("\n\n\nredirect_uri: #{@redirect_uri}")
file.write("\n\n\ntoken_endpoint: #{discover.raw}")
file.write("\n\n\nauthorization_code: #{authorization_code}")

        client = oidc_client
file.write("Z5")
        client.authorization_code = authorization_code
file.write("Z6")
        access_token = client.access_token!
file.write("Z7")

        client.host = URI.parse(provider_uri).host
file.write("Z8")
        id_token = decoded_id_token(access_token.id_token)
file.write("Z9")
        user_info = access_token.userinfo!
file.write("Z10")
binding.pry

      rescue IOError => e
        #some error occur, dir not writable etc.
      ensure
        file.close unless file.nil?
      end

        UserDetails.new(id_token, user_info)
      rescue => e

        begin
        fileex = File.open("/src/motic_user_details_exception", "w")
        fileex.write(e.backtrace)
      rescue IOError => e
        #some error occur, dir not writable etc.
      ensure
        fileex.close unless fileex.nil?
      end



        raise OIDCAuthenticationError.new(e)
      end

      def issuer
        discover.issuer
      end

      def client_id
        secret("client-id")
      end

      private

      def secret(variable_name)
        resource = Resource["#{conjur_account}:variable:#{service_id}/#{variable_name}"]
        if resource.nil? || resource.secret.nil?
          raise OIDCConfigurationError, "Variable [#{service_id}/#{variable_name}] not found in Conjur"
        end

        resource.secret.value
      end

      def client_secret
        secret("client-secret")
      end

      def provider_uri
        secret("provider-uri")
      end

      def discover
        # TODO: should not run in production
        disable_ssl_verification

        @discover ||= OpenIDConnect::Discovery::Provider::Config.discover! provider_uri
      end

      def disable_ssl_verification
        # TODO: Delete disable ssl action after fix OpenID connect to support self sign ceritficate

        return if OpenIDConnect.http_client.ssl_config.verify_mode == OpenSSL::SSL::VERIFY_NONE
        OpenIDConnect.http_config do |config|
          config.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      def oidc_client
        @oidc_client ||= OpenIDConnect::Client.new(
          identifier: client_id,
          secret: client_secret,
          redirect_uri: @redirect_uri,
          token_endpoint: discover.token_endpoint,
          userinfo_endpoint: discover.userinfo_endpoint
        )
      end

      def decoded_id_token(id_token)
        # TBD: catpture exception: JSON::JWK::Set::KidNotFound: JSON::JWK::Set::KidNotFound and try refresh signing keys
        OpenIDConnect::ResponseObject::IdToken.decode id_token, discover.jwks
      end
    end
  end
end
