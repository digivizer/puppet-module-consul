# Install class for Consul
class consul::install(
    $version         = '0.7.1',
) {
  file { '/var/local/consul':
    ensure => directory,
    mode   => '0700',
    owner  => 'consul',
    group  => 'consul',
  }

  group { 'consul': ensure => present }
  user { 'consul': gid => 'consul' }

  file { '/usr/local/bin/install-consul':
    ensure => file,
    source => 'puppet:///modules/consul/usr/local/bin/install-consul',
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
  }

  ensure_packages('unzip', { ensure => present })

  exec { 'download and install consul':
    command => "/usr/local/bin/install-consul ${version}",
    creates => "/usr/local/bin/consul-${version}",
    require => Package['unzip'],
  }
}
