# frozen_string_literal: true

namespace :account do
  def signing_key_key(account)
    ['authn', account].join(':')
  end

  desc 'Test whether the token-signing key already exists'
  task :exists, ['account'] => ['environment'] do |_t, args|
    puts !!Slosilo[signing_key_key args[:account]]
  end

  desc 'Create an account'
  task :create, ['account'] => ['environment'] do |_t, args|
    Account.find_or_create_accounts_resource
    begin
      api_key = Account.create args[:account]
      account = Account.new args[:account]
      warn "Created new account account '#{account.id}'"
      puts "Token-Signing Public Key: #{account.token_key}"
      puts "API key for admin: #{api_key}"
    rescue Exceptions::RecordExists
      warn "Account '#{args[:account]}' already exists"
      exit 1
    end
  end

  desc 'Delete an account'
  task :delete, ['account'] => ['environment'] do |_t, args|
    begin
      Account.new(args[:account]).delete
      warn "Deleted account '#{args[:account]}'"
    rescue Sequel::NoMatchingRow
      warn "Account '#{args[:account]}' not found"
      exit 1
    end
  end
end
