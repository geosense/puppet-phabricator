class phabricator::phab_config (
  $path            = $phabricator::params::path,
  $vcs_user        = $phabricator::params::vcs_user,
  $phd_user        = $phabricator::params::phd_user,
  $phabdir         = $phabricator::params::phabdir,
  $conftemplate    = $phabricator::params::conftemplate,
  $conffile        = $phabricator::params::conffile,
  $confdir         = $phabricator::params::confdir,
  $owner           = $phabricator::params::owner,
  $group           = $phabricator::params::group,
  $mysql_rootpass  = $phabricator::params::mysql_rootpass,
  $mysql_host      = $phabricator::params::mysql_host,
  $mysql_root_user = $phabricator::params::mysql_root_user,
  $base_uri        = $phabricator::params::base_uri) {

  if (true) {
    if $conftemplate == '' {
      $cnftemplate = template("phabricator/${conffile}.erb")
    } else {
      $cnftemplate = $conftemplate
    }

    file { $confdir:
      ensure  => directory,
      owner   => $owner,
      group   => $group,
      require => Vcsrepo[$phabdir],
    }

    file { $conffile:
      ensure  => present,
      path    => "${confdir}/${conffile}",
      content => $cnftemplate,
      owner   => $owner,
      group   => $group,
      require => File[$confdir],
      notify  => Service[$nginx::service::service_name],
    }
  }

  # Because we want phabricator to load its db schemata for the first
  # time after creating this file, we notify to upgrade_storage; we do
  # it here because this is where we end the db configuration. We also
  # want mysql::server to be configured with the correct password and,
  # therefore, we ensure this dependency.
  file { 'ENVIRONMENT':
    ensure  => present,
    path    => "${phabdir}/conf/local/ENVIRONMENT",
    content => "custom/default",
    require => [Class['mysql::server'], Package[$nginx::params::package_name], Class['phabricator::phab_install'], File[$conffile],],
    notify  => [Service[$nginx::service::service_name], Exec['upgrade_storage'],],
  }->

  phabricator::config_tool { 'set_mysql_host':
    name    => 'mysql.host',
    value   => $mysql_host,
    phabdir => $phabdir
  }->

  phabricator::config_tool { 'set_mysql_user':
    name    => 'mysql.user',
    value   => $mysql_root_user,
    phabdir => $phabdir
  }->

  phabricator::config_tool { 'set_mysql_pass':
    name    => 'mysql.pass',
    value   => $mysql_rootpass,
    phabdir => $phabdir
  }->

  phabricator::config_tool { 'set_base_uri':
    name    => 'phabricator.base-uri',
    value   => $base_uri,
    phabdir => $phabdir
  }->

  phabricator::config_tool { 'set_phd_user':
    name    => 'phd.user',
    value   => $phd_user,
    phabdir => $phabdir
  }->

  phabricator::config_tool { 'set_vcs_user':
    name    => 'diffusion.ssh-user',
    value   => $vcs_user,
    phabdir => $phabdir
  }->

  exec { 'upgrade_storage':
    command     => "storage upgrade --force",
    require     => Service[$mysql::params::server_service_name],
    path        => "${phabdir}/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
    cwd         => $phabdir,
    refreshonly => true,
  }

  file { '/var/repo':
    owner   => $vcs_user,
    group   => $group,
    mode    => 775,
    ensure  => "directory",
    recurse => true,
  }

}
