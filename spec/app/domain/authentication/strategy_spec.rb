require 'spec_helper'

describe 'Authentication::Strategy' do
  let(:service) { instance_double Resource, :service }
  let(:role) do
    instance_double Role, :role, 
      account: 'the-account',
      id: 'the-account:user:alice'
  end
  let(:authenticator_name) { 'authn-test' }

  subject(:input) do
    Authentication::Strategy::Input.new(
      authenticator_name: authenticator_name,
      service: service,
      role: role,
      password: 'secret'
    )
  end

  describe 'Authentication::Strategy::Input#to_access_request' do
    subject { input }

    let (:two_authenticator_env) do
      {'CONJUR_AUTHENTICATORS' => 'authn-one, authn-two'}
    end

    let (:blank_env) { Hash.new }
    
    context "An ENV lacking CONJUR_AUTHENTICATORS" do

      it "whitelists only the default Conjur authenticator" do
        services = subject.to_access_request(blank_env).whitelisted_webservices
        expect(services.to_a.size).to eq(1)
        expect(services.first.name).to eq(
          Authentication::Strategy.default_authenticator_name
        )
      end
    end

    context "An ENV containing CONJUR_AUTHENTICATORS" do

      it "whitelists exactly those authenticators as webservices" do
        services = subject
          .to_access_request(two_authenticator_env)
          .whitelisted_webservices
          .map(&:name)
        expect(services).to eq(['authn-one', 'authn-two'])
      end
    end

    it "passes the username through as the user_id" do
      access_request = subject.to_access_request(blank_env)
      expect(access_request.user_id).to eq(subject.username)
    end

    context "An input with a service_id" do

      it "creates a Webservice with the correct authenticator_name" do
        webservice = subject.to_access_request(blank_env).webservice
        expect(webservice.authenticator_name).to eq(subject.authenticator_name)
      end

      it "creates a Webservice with the correct service_id" do
        webservice = subject.to_access_request(blank_env).webservice
        expect(webservice.service_id).to eq(subject.service_id)
      end

      it "creates a Webservice with the correct account" do
        webservice = subject.to_access_request(blank_env).webservice
        expect(webservice.account).to eq(subject.account)
      end
    end

    context "An input without a service_id" do
      let(:service) { nil }

      it "creates a Webservice without a service_id" do
        webservice = subject.to_access_request(blank_env).webservice
        expect(webservice.service_id).to be_nil
      end
    end


  ####################################
  # Available Authenticators - doubles
  ####################################

  def authenticator(pass:)
    double('Authenticator').tap do |x|
      allow(x).to receive(:valid?).and_return(pass)
    end
  end

  let (:authenticators) do
    {
      'authn-always-pass' => authenticator(pass: true),
      'authn-always-fail' => authenticator(pass: false)
    }
  end

  ####################################
  # Security doubles
  ####################################

  let (:passing_security) do
    double('Security').tap do |x|
      allow(x).to receive(:validate)
    end
  end

  let (:failing_security) do
    double('Security').tap do |x|
      allow(x).to receive(:validate).and_raise('FAKE_SECURITY_ERROR')
    end
  end

  ####################################
  # ENV doubles
  ####################################

  let (:two_authenticator_env) do
    {'CONJUR_AUTHENTICATORS' => 'authn-always-pass, authn-always-fail'}
  end

  let (:blank_env) { Hash.new }

  ####################################
  # TokenFactory double
  ####################################

  # NOTE: For _this_ class, the details of actual Conjur tokens are irrelevant
  #
  let (:a_new_token) { 'A NICE NEW TOKEN' }

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end
  
  let(:actual_token) { subject.conjur_token(input) }

#  ____  _   _  ____    ____  ____  ___  ____  ___ 
# (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
#   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
#  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/


  context "An unavailable authenticator" do
    let(:authenticator_name) { 'AUTHN-MISSING' }

    it "raises AuthenticatorNotFound" do
      expect{ subject.conjur_token(input) }.to raise_error(
        Authentication::Strategy::AuthenticatorNotFound
      )
    end
  end

  context "An available authenticator" do
    context "that passes Security checks" do

      subject do
        Authentication::Strategy.new(
          authenticators: authenticators,
          security: passing_security,
          env: two_authenticator_env,
          token_factory: token_factory
        )
      end

      context "and receives invalid credentials" do

        it "raises InvalidCredentials" do
          input_ = input(authenticator_name: 'authn-always-fail')
          expect{ subject.conjur_token(input_) }.to raise_error(
            Authentication::Strategy::InvalidCredentials
          )
        end
      end

      context "and receives valid credentials" do
        let(:authenticator_name) { 'authn-always-pass' }
        it "returns a new token" do
          expect(actual_token).to equal(a_new_token)
        end
      end

    end

    context "that fails Security checks" do

      subject do
        Authentication::Strategy.new(
          authenticators: authenticators,
          security: failing_security,
          env: two_authenticator_env,
          token_factory: token_factory
        )
      end

      it "raises an error" do
        input_ = input(authenticator_name: 'authn-always-pass')
        expect{ subject.conjur_token(input_) }.to raise_error(
          /FAKE_SECURITY_ERROR/
        )
      end
    end

  end
end
end
