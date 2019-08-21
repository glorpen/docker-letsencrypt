class puppetizer_main::service {
  puppetizer::service { 'cron':
    run_content => "#!/bin/sh -e\nexec crond -f -d 7",
  }
}
