  notice('MODULAR: zaqar/mongo.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))

  $zaqar_hash          = hiera_hash('zaqar', {})
  $mongodb_port        = '27017'

  $mongo_nodes         = get_nodes_hash_by_roles(hiera_hash('network_metadata'), ['primary-zaqar-mongo','zaqar-mongo'])
  $mongo_address_map   = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'zaqar/mongodb')

  $mongo_hosts         = suffix(values($mongo_address_map), ":${mongodb_port}")
  $bind_address        = get_network_role_property('zaqar/mongodb', 'ipaddr')
  $use_syslog          = hiera('use_syslog', true)
  $debug               = hiera('debug', false)
  $roles               = hiera('roles')

  $replset_name        = 'zaqar'
  $keyfile             = '/etc/mongodb.key'
  $astute_keyfile      = '/var/lib/astute/mongodb/mongodb.key'

  # TODO(pchechetin): Make database name configurable
  $zaqar_database = 'zaqar'

  if $debug {
    $verbositylevel = 'vv'
  } else {
    $verbositylevel = 'v'
  }

  if $use_syslog {
    $logpath = false
  } else {
    # undef to use defaults
    $logpath = undef
  }

  $oplog_size = undef


  file { $keyfile:
    content => file($astute_keyfile),
    owner   => 'mongodb',
    mode    => '0600',
    require => Package['mongodb_server'],
    before  => Service['mongodb'],
  }

  $user   = 'mongodb'
  $group  = 'mongodb'
  $dbpath = '/var/lib/mongo/mongodb'

  #TODO(mmalchuk) should be fixed in the File[$dbpath] resource in upstream
  #               exec resource used only to set permissions more quickly
  exec { 'dbpath set permissions':
    command     => "chown -R ${user}:${group} ${dbpath}",
    path        => ['/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => File[$dbpath],
    before      => Service['mongodb']
  }

  class { '::mongodb::globals':
    version => '2.6.10',
  } ->

  class { '::mongodb::client': } ->

  class { '::mongodb::server':
    user            => $user,
    group           => $group,
    package_ensure  => true,
    port            => $mongodb_port,
    verbose         => false,
    verbositylevel  => $verbositylevel,
    syslog          => $use_syslog,
    logpath         => $logpath,
    journal         => true,
    bind_ip         => [ '127.0.0.1', $bind_address ],
    auth            => true,
    replset         => $replset_name,
    keyfile         => $keyfile,
    directoryperdb  => true,
    fork            => false,
    profile         => '1',
    oplog_size      => $oplog_size,
    dbpath          => $dbpath,
    create_admin    => true,
    admin_password  => $zaqar_hash['db_password'],
    store_creds     => true,
    replset_members => $mongo_hosts,
  } ->

  mongodb::db { $zaqar_database:
    user     => 'zaqar',
    password => $zaqar['db_password'],
    roles    => [ 'readWrite', 'dbAdmin' ],
  }

  if ! roles_include(['controller', 'primary-controller']) {
    sysctl::value { 'net.ipv4.tcp_keepalive_time':
      value => '300',
    }
  }


