class phabricator::apache_install ($phabdir = $phabricator::params::phabdir, $hostname = $phabricator::params::hostname) {
  class { 'nginx':
  }

  package { 'php5-fpm': }

  apache::vhost { $hostname:
    port            => '80',
    docroot         => "${$phabdir}/webroot",
    custom_fragment => template('phabricator/apache-vhost-default.conf.erb'),
  }

  $www_root = "${phabdir}/webroot",

  nginx::resource::vhost { "${name}.${::domain} ${name}":
    ensure                => present,
    www_root              => $www_root,
    index_files           => [ 'index.php' ],
    try_files             => ['$uri $uri/ /index.php?$is_args$args'],    
  }

  nginx::resource::location { "${name}_root":
    ensure          => present,
    vhost           => "${name}.${::domain} ${name}",
    www_root        => $www_root,
    location        => '~ \.php$',
    index_files     => ['index.php', 'index.html', 'index.htm'],
    proxy           => undef,
    fastcgi         => 'unix:/var/run/php5-fpm.sock',
    fastcgi_script  => undef,
    location_cfg_append => {
      fastcgi_connect_timeout => '3m',
      fastcgi_read_timeout    => '3m',
      fastcgi_send_timeout    => '3m'
      fastcgi_index           => 'index.php',
      fastcgi_split_path_info => '^(.+\.php)(/.+)$'
    }
  }

}
