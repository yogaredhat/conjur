require 'openid_connect'

module Authentication
  module AuthnOidc
    class OidcClient

      def initialize(client_id:, client_secret:, redirect_uri:, provider_uri:)
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
        @provider_uri = provider_uri
      end

      def oidc_client
        @oidc_client ||= OpenIDConnect::Client.new(
          identifier: @client_id,
          secret: @client_secret,
          redirect_uri: @redirect_uri,
          token_endpoint: discovered_resource.token_endpoint,
          userinfo_endpoint: discovered_resource.userinfo_endpoint
        )
      end

      def configure(authorization_code:, host:)
        oidc_client.authorization_code = authorization_code
        oidc_client.host = host
      end

      # TODO: capture exception: JSON::JWK::Set::KidNotFound and try refresh
      # signing keys
      def id_token
        OpenIDConnect::ResponseObject::IdToken.decode(
          access_token.id_token, discovered_resource.jwks
        )
      end

      def user_info
        access_token.userinfo!
      end

      def issuer
        discovered_resource.issuer
      end

      private

      def access_token
        @access_token ||= oidc_client.access_token!
      rescue Rack::OAuth2::Client::Error => e
        raise OIDCAuthenticationError, e.message
      end

      def discovered_resource
        @discovered_resource ||= OpenIDConnect::Discovery::Provider::Config.discover!(@provider_uri)
      end
    end
  end
end
