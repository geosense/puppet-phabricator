class phabricator::nginx_install 
(
  $phabdir = $phabricator::params::phabdir,
  $hostname = $phabricator::params::hostname
) {
  include nginx

  $www_root = "${phabdir}/webroot"

  nginx::resource::vhost { "${hostname} ${name}":
    ensure              => present,
    www_root            => $www_root,
    index_files     => ['index.php'],
    location_raw_append => 
'if ( !-f $request_filename )
{
  rewrite ^/(.*)$ /index.php?__path__=/$1 last;
  break;
}',
  }

  nginx::resource::location { "${hostname}_index":
    ensure          => present,
    vhost           => "${hostname} ${name}",
    www_root        => $www_root,
    location        => '/index.php',
    index_files     => ['index.php', 'index.html', 'index.htm'],
    proxy           => undef,
    fastcgi         => 'unix:/var/run/php5-fpm.sock',
    fastcgi_script  => undef,
    location_cfg_append => {
      fastcgi_connect_timeout => '3m',
      fastcgi_read_timeout    => '3m',
      fastcgi_send_timeout    => '3m',
      fastcgi_index           => 'index.php',
      fastcgi_split_path_info => '^(.+\.php)(/.+)$',
    }
  }

}
