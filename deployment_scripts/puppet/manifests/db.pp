notice('MODULAR: fuel-plugin-zaqar/db.pp')

$mysql              = hiera_hash('mysql', {})
$zaqar              = hiera_hash('zaqar', {})
$db_host            = hiera('database_vip')
$db_root_user       = pick($mysql['root_user'], 'root')
$db_root_password   = $mysql['root_password']

$db_user      = 'zaqar'
$db_password  = $zaqar['db_password']
$db_name      = 'zaqar'
$allowed_hosts = [ 'localhost', '127.0.0.1', '%' ]

class { '::zaqar::db::mysql':
  user          => $db_user,
  password      => $db_password,
  dbname        => $db_name,
  allowed_hosts => $allowed_hosts,
}

class { '::openstack::galera::client':
  custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
}

class { '::osnailyfacter::mysql_access':
  db_host     => $db_host,
  db_user     => $db_root_user,
  db_password => $db_root_password,
}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server

Class['::openstack::galera::client'] ->
  Class['::osnailyfacter::mysql_access'] ->
    Class['::zaqar::db::mysql']
