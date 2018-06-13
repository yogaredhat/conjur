module Authentication
  class AuditLog
    def self.record_authn_event(role_id:, webservice_id:, authenticator_name:,
                                success:, message: nil)
      event = ::Audit::Event::Authn.new(
        role_id: role_id,
        authenticator_name: authenticator_name,
        service_id: webservice_id
      )
      binding.pry
      if success
        event.emit_success
      else
        event.emit_failure message
      end
    end
  end
end
