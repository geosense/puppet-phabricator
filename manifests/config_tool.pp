define phabricator::config_tool ($exec = $title, $name, $value, $phabdir) {
  exec { $exec:
    command => "config set ${name} ${value}",
    path    => "${phabdir}/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
    cwd     => $phabdir,
    notify  => Service[$nginx::service::service_name]
  }

}
