class AuthorizationCertificate < Sequel::Model
  unrestrict_primary_key

  attr_encrypted :key, aad: lambda { |r| [r.resource_id, r.privilege].join(':') }
  alias_method :to_der, :certificate

  def before_save
    create_certificate unless self.certificate
    super
  end

  def certificate
    to_der && OpenSSL::X509::Certificate.new(to_der)
  end

  def to_pem
    certificate.to_pem
  end

  def issue role_id:, client_key:
    OpenSSL::X509::Certificate.new.tap do |cert|
      cert.version = 2
      cert.serial = (Time.now.to_f * 1000).to_i % 2**32
      cert.subject = OpenSSL::X509::Name.parse "/CN=#{role_id}"
      cert.issuer = certificate.subject
      cert.public_key = client_key.public_key
      cert.not_before = Time.now
      # TODO: consider what's the right expiration
      cert.not_after = cert.not_before + 8 * 60
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = certificate
      cert.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
      cert.add_extension(ef.create_extension("keyUsage","digitalSignature", true))
      cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      cert.sign(private_key, OpenSSL::Digest::SHA256.new)
    end
  end

  private

  def private_key
    key && OpenSSL::PKey::RSA.new(key)
  end

  def create_certificate
    key = OpenSSL::PKey::RSA.new 2048
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse "/CN=#{resource_id}/CN=#{privilege}"
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.now
    # TODO: consider what's the right expiration and what happens when it does expire
    cert.not_after = cert.not_before + 2 * 365 * 24 * 60 * 60
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
    cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
    cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
    cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
    cert.sign(key, OpenSSL::Digest::SHA256.new)

    self.key = key.to_der
    self.certificate = cert.to_der
  end
end
