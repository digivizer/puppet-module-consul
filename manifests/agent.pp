# installs and configures Consul agents (both client and server)
define consul::agent(
    $server         = false,
    $dc             = 'dc1',
    $join           = undef,
    $client_address = '127.0.0.1',
    $advertise      = undef,
    $expect         = undef,
) {
  include consul::install

  $work_dir = "/var/local/consul/${name}"

  file { $work_dir:
    ensure => directory,
    mode   => '0700',
    owner  => 'consul',
    group  => 'consul',
  }

  if $server {
    if $expect == undef {
      fail "I don't know how many servers to expect"
    }

    $server_opt = " -server -bootstrap-expect=${expect}"
  }

  if $advertise {
    $adv_opt = " -advertise ${advertise}"
  }

  if $join {
    if $join =~ /:.*:/ {
      $join_opt = " -retry-join='[${join}]:8301'"
    } else {
      $join_opt = " -retry-join=${join}"
    }
  }

  class { 'datadog_agent::integrations::consul':
    url               => 'http://localhost:8500',
    catalog_checks    => true,
    new_leader_checks => true,
  }

  file { "${work_dir}/default.json":
    content => '{"statsd_addr": "127.0.0.1:8125"}',
    mode    => '0700',
    owner   => 'consul',
    group   => 'consul',
  }

  daemontools::service { "consul-${name}":
    command     => "/usr/local/bin/consul agent${server_opt}${join_opt}${adv_opt} -client=${client_address} -node=${name} -dc=${dc} -data-dir=${work_dir} -pid-file=${work_dir}.pid -config-file=${work_dir}/default.json",
    user        => 'consul',
    require     => File[$work_dir, "${work_dir}/default.json"],
    environment => {
      'GOMAXPROCS' => '2',
    }
  }
}
