class puppetizer_main(
  Boolean $agree_tos = false,
  String $email,
  Hash[String, Optional[Array[String]]] $certonly = {},
  String $config_dir = '/etc/letsencrypt',
  String $consul_key = 'letsencrypt',
  String $consul_token,
  String $consul_host,
  Integer $consul_port = 8500,
  String $consul_scheme = 'http'
){

  $_agree_tos = $facts['puppetizer']['building']?{
    true => true,
    default => $agree_tos
  }
  $log_dir = '/var/log'

  class { letsencrypt:
    email             => $email,
    renew_cron_ensure => 'present',
    package_ensure    => 'installed',
    package_name      => 'certbot',
    package_command   => 'certbot',
    install_method    => 'package',
    agree_tos         => $_agree_tos,
    config_dir        => $config_dir,
    manage_config     => true,
    config            => {
      'logs-dir'        => $log_dir,
      'max-log-backups' => 0
    },
    require           => [
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
    mode => 'u=rwx,go=rx'
  }

  $certonly.each | $_name, $domains | {
    if $domains {
      $_domains = $domains
      $ensure = 'present'
    } else {
      $_domains = []
      $ensure = 'absent'
    }

    letsencrypt::certonly { $_name:
      domains              => $_domains,
      manage_cron          => true,
      cron_hour            => [0,12],
      cron_minute          => seeded_rand(59, $_name),
      suppress_cron_output => true,
      deploy_hook_commands => [$hook_path],
    }
  }

  # fixes
  Exec <| title == 'initialize letsencrypt' |> {
    noop => true
  }
  # some files from puppet/letsencrypt
  file { '/usr/local/sbin':
    ensure  => directory,
    recurse => false
  }
  # logging to stdout
  file { "${log_dir}/letsencrypt.log":
    ensure => 'link',
    target => '/proc/1/fd/1'
  }
}
