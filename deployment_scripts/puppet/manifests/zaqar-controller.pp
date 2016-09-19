notice('fuel-plugin-zaqar/zaqar-controller.pp')

package { 'zaqar-server':
  ensure => 'present',
}

