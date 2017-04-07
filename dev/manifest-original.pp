class { 'conjur':
  appliance_url      => 'http://possum',
  authn_login        => 'host/host-01',
  host_factory_token => Sensitive('<HOST_FACTORY_TOKEN>')
}

file { '/tmp/dbpass':
  ensure    => file,
  content   => conjur::secret('inventory-db/password'),
  show_diff => false,  # don't log file content!
}
