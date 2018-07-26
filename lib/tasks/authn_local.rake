# frozen_string_literal: true

namespace :authn_local do
  desc 'Run the authn-local service'
  task :run, %w[socket queue_length timeout] => :environment do |_t, args|
    socket = args['socket'] || ENV['CONJUR_AUTHN_LOCAL_SOCKET']
    queue_length = args['queue_length'] || ENV['CONJUR_AUTHN_LOCAL_QUEUE_LENGTH']
    timeout = args['timeout'] || ENV['CONJUR_AUTHN_LOCAL_TIMEOUT']

    AuthnLocal.run socket: socket, queue_length: queue_length, timeout: timeout
  end
end
