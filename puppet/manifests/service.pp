class puppetizer_main::service {

  $store_script = '/usr/local/bin/letsencrypt-store'
  file { $store_script:
    mode => 'a=rx,u+w',
    content => epp('puppetizer_main/consul.py.epp', {
      'letsencrypt_key' => $puppetizer_main::consul_key,
      'letsencrypt_etc' => $puppetizer_main::config_dir,
      'consul_token'    => $puppetizer_main::consul_token,
      'consul_host'     => $puppetizer_main::consul_host,
      'consul_port'     => $puppetizer_main::consul_port,
      'consul_scheme'   => $puppetizer_main::consul_scheme
    })
  }

  exec { 'letsencrypt-store':
    command => $store_script,
    noop    => $facts['puppetizer']['building']
  }
  puppetizer::service { 'cron':
    start_content => "#!/bin/sh -e\nexec crond -f -d 7",
    stop_content => "#!/bin/sh -e\nexec kill \$1",
    require => Exec['letsencrypt-store']
  }
}
