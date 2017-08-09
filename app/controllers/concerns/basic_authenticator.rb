module BasicAuthenticator
  extend ActiveSupport::Concern
  
  def perform_basic_authn
    if request.authorization =~ /^Basic /
      Provider::Login::Basic.new(account, authentication, request).perform_login 
    end
  end
end
