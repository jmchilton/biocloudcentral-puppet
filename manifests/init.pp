class biocloudcentral(
  repository_url = 'https://github.com/chapmanb/biocloudcentral',
  db_name = 'biocloudcentral',
  db_username = 'biocloudcentral',
  db_password = '',
  db_host = '',
  db_port = '5432',
) {
  include biocloudcentral::config

  # Local variables needed for templates
  $destination = $biocloudcentral::config::destination
  $biocloudcentral_user = $biocloudcentral::config::user
  $log_dir = $biocloudcentral::config::log_dir

  user { "$biocloudcentral::config::user":
    ensure => present,
    home => "$biocloudcentral::config::home",
    shell => "/bin/bash",
  }
 
  file { "$biocloudcentral::config::home":
    ensure => directory,
    owner => "$biocloudcentral::config::user",
    require => User["$biocloudcentral::config::user"],
  }

  vcsrepo { "$biocloudcentral::config::destination":
    ensure => present,
    provider => git,
    source => $repository_url,
    #revision => $biocloudcentral::config::repository_tag,
    owner => "$biocloudcentral::config::user",
    require => User["$biocloudcentral::config::user"]
  }

  exec { 'biocloud_virtualenv':
    command => "/bin/bash -c 'virtualenv --no-site-packages .; source bin/activate; pip install -r requirements.txt'",
    creates => "$biocloudcentral::config::destination/bin",
    require => Vcsrepo["$biocloudcentral::config::destination"],
    user => "$biocloudcentral::config::user",
  }

  file { "$biocloudcentral::config::destination/biocloudcentral/local_setting.py":
    content => template("biocloudcentral/local_settings.py.erb"),
    require => Vcsrepo["$horizon::config::destination"],
    owner => "$horizon::config::user",    
  }

  exec { "biocloudcentral_syncdb":
    command => "/bin/bash -c 'source bin/activate; python biocloudcentral/manage.py syncdb; python biocloudcentral/manage.py migrate biocloudcentral'",
    cwd => "$biocloudcentral::config::destination",
    user => "$biocloudcentral::config::user",
    require => File["$biocloudcentral::config::destination/biocloudcentral/local_setting.py"]
  }

  file { "$biocloudcentral::config::log_dir":
    ensure => directory,
    owner => "$biocloudcentral::config::user",
    mode => 770,
  }

}
