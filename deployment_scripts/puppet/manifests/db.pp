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

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
