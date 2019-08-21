class puppetizer_main::fixes {
  Exec <| title == 'initialize letsencrypt' |> {
    noop => true
  }
  # some files from puppet/letsencrypt
  file { '/usr/local/sbin':
    ensure  => directory,
    recurse => false
  }
  # logging to stdout
  file { "${puppetizer_main::log_dir}/letsencrypt.log":
    ensure => 'link',
    target => '/proc/1/fd/1'
  }
}
