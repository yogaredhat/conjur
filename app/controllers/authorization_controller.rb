require 'openssl'

class AuthorizationController < RestController
  include FindResource
  include AssumedRole

  def show
    send_data certificate.to_pem, type: :pem
  end

  def sign
    raise Forbidden unless assumed_role.allowed_to?(privilege, resource)
    key = OpenSSL::PKey::RSA.new request.body.read
    cert = certificate.issue role_id: assumed_role.id, client_key: key
    send_data cert.to_pem, type: :pem
  end

  private

  def certificate
    resource.authorization_certificate(privilege)
  end

  def privilege
    @privilege ||= params.require :privilege
  end
end
