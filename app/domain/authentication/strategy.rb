module Authentication

  # - Runs security checks
  # - Finds the appropriate authenticator
  # - Validates credentials against
  # - Returns a new token
  class Strategy < ::Dry::Struct

    AuthenticatorNotFound = ::Util::ErrorClass.new(
      "'{0}' wasn't in the available authenticators")
    InvalidCredentials = ::Util::ErrorClass.new(
      "Invalid credentials")


    class Input < ::Dry::Struct
      attribute :authenticator_name, Types::NonEmptyString
      attribute :service, Types::Any.optional
      attribute :role, Types::Any
      attribute :password, Types::NonEmptyString

      # Convert this Input to an Security::AccessRequest
      #
      def to_access_request(env)
        ::Authentication::Security::AccessRequest.new(
          webservice: service,
          whitelisted_webservices: 
            env['CONJUR_AUTHENTICATORS'].split(',') || Authentication::Strategy.default_authenticator_name,
          role: role
        )
      end
    end

    def self.default_authenticator_name
      'authn'
    end

    # required constructor parameters
    #
    attribute :authenticators, ::Types::Hash

    # optional constructor parameters
    #
    attribute :security, ::Types::Any.default{ ::Authentication::Security.new }
    attribute :env, ::Types::Any.default(ENV)
    attribute :token_factory, ::Types::Any.default{ TokenFactory.new }

    def conjur_token(input)
      authenticator = authenticators[input.authenticator_name]

      validate_authenticator_exists(input, authenticator)
      validate_security(input)
      validate_credentials(input, authenticator)

      new_token(input)
    end

    private

    def validate_authenticator_exists(input, authenticator)
      raise AuthenticatorNotFound, input.authenticator_name unless authenticator
    end

    def validate_security(input)
      security.validate(input.to_access_request(env))
    end

    def validate_credentials(input, authenticator)
      raise InvalidCredentials unless authenticator.valid?(input)
    end

    def new_token(input)
      token_factory.signed_token(
        account: input.role.account,
        username: Role.username_from_roleid(input.role.id)
      )
    end
  end

end
