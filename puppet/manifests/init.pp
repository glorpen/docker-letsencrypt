class puppetizer_main(
  String $consul_host,
  Optional[String] $email = undef,
  Optional[String] $consul_token = undef,
  String $consul_key = 'letsencrypt',
  Integer $consul_port = 8500,
  String $consul_scheme = 'http',
  Stdlib::Unixpath $config_dir = '/etc/letsencrypt',
  Boolean $agree_tos = false,
  Hash[String, Struct[{'domains'=>Optional[Array[String]], 'plugin'=>Letsencrypt::Plugin, 'test'=>Optional[Boolean]}]] $certs = {},
  Optional[String] $proxy_url = undef,
  Integer $proxy_tries = 10,
  Optional[Integer] $proxy_req_http_code = undef,
  Optional[String] $wait_before_init = undef
){

  $_agree_tos = $facts['puppetizer']['building']?{
    true => true,
    default => $agree_tos
  }
  $log_dir = '/var/log'
  $_unsafe_reg = $email?{
    undef   => true,
    default => false
  }

  class { 'letsencrypt':
    email               => $email,
    renew_cron_ensure   => 'present',
    package_ensure      => 'installed',
    package_name        => 'certbot',
    package_command     => 'certbot',
    install_method      => 'package',
    agree_tos           => $_agree_tos,
    config_dir          => $config_dir,
    manage_config       => true,
    unsafe_registration => $_unsafe_reg,
    config              => {
      'logs-dir'        => $log_dir,
      'max-log-backups' => 0
    },
    require             => [
      File['/usr/local/sbin'],
      File["${log_dir}/letsencrypt.log"]
    ]
  }

  $hook_path = '/usr/local/bin/letsencrypt-hook'
  file { $hook_path:
    ensure  => present,
    content => epp('puppetizer_main/deploy-hook.py.epp', {
      'letsencrypt_key' => $consul_key,
      'consul_token'    => $consul_token,
      'consul_host'     => $consul_host,
      'consul_port'     => $consul_port,
      'consul_scheme'   => $consul_scheme
    }),
    mode    => 'u=rwx,go=rx'
  }

  # optional wait after starting in swarm
  exec { 'wait before init':
    command   => "/bin/sleep ${wait_before_init}",
    timeout   => 0,
    logoutput => true,
    noop      => $wait_before_init == undef or ! $facts['puppetizer']['initializing']
  }
  Exec['wait before init']
  ->Letsencrypt::Certonly <| |>

  if ($proxy_url) {
    if $proxy_req_http_code != undef {
      $_proxy_arg = "--http-code ${proxy_req_http_code}"
    } else {
      $_proxy_arg = ''
    }
    exec { 'wait for proxy':
      command   => "/usr/local/bin/letsencrypt-wait-for-proxy ${proxy_url} ${proxy_tries} ${_proxy_arg}",
      timeout   => 0,
      logoutput => true
    }

    Exec['wait before init']
    ->Exec['wait for proxy']
    ->Letsencrypt::Certonly <| |>
  }

  $certs.each | $_name, $conf | {
    if $conf['domains'] {
      $_domains = $conf['domains']
      $ensure = 'present'
    } else {
      $_domains = [$_name]
      $ensure = 'absent'
    }

    if $conf['test'] == true {
      $_args_test = ['--test-cert']
    } else {
      $_args_test = []
    }

    letsencrypt::certonly { $_name:
      domains              => $_domains,
      manage_cron          => true,
      cron_hour            => [0,12],
      cron_minute          => seeded_rand(59, $_name),
      suppress_cron_output => true,
      deploy_hook_commands => [$hook_path],
      additional_args      => $_args_test,
      plugin               => $conf['plugin']
    }
  }

  include puppetizer_main::fixes
  include puppetizer_main::service
}
