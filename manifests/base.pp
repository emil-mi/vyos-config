class vyatta::base($hostname, $name_servers=undef, $name_servers_mode='minimum', $ntp_servers=undef, $ntp_servers_mode='inclusive', $time_zone=undef, $pkg_repo_mode='default') inherits vyatta {

    validate_re($ntp_servers_mode, '^(minimum|inclusive)$',
      "$ntp_servers_mode is not supported for ntp_servers_mode. Allowed values are 'minimum' and 'inclusive' .")
      
    validate_re($name_servers_mode, '^(minimum|inclusive)$',
      "$name_servers_mode is not supported for name_servers_mode. Allowed values are 'minimum' and 'inclusive' .")

    validate_re($pkg_repo_mode, '^(minimum|default|skip)$',
      "$pkg_repo_mode is not supported for pkg_repo_mode. Allowed values are 'minimum', 'default' and 'skip' .")

	file {'/boot/grub/grub.cfg': ensure=>present,}
	exec { "/bin/sed -i -e '/set timeout=[0-9]\\+/s/[0-9]\\+/0/' /boot/grub/grub.cfg":
		onlyif => "/usr/bin/test `/bin/grep 'set timeout=[1-9][0-9]*' '/boot/grub/grub.cfg' | /usr/bin/wc -l` -ne 0" }
	exec { "/bin/sed -i -e '/if sleep --verbose --interruptible [0-9]\\+ ; then/s/[0-9]\\+/0/' /boot/grub/grub.cfg": 
		onlyif => "/usr/bin/test `/bin/grep 'if sleep --verbose --interruptible [1-9][0-9]* ; then' '/boot/grub/grub.cfg' | /usr/bin/wc -l` -ne 0"}

	vy_host_name {$hostname:
	}
	
	if $time_zone
	{
		vy_timezone { $time_zone:
		}
	}

	if ($ntp_servers)
	{
		if (!empty($ntp_servers))
		{
			vy_ntp_server{ $ntp_servers :
				ensure => present
			}
		}
		if ($ntp_servers_mode==inclusive)
		{
			resources { 'vy_ntp_server':
				purge => true
			}		
		}
	}
	
	if ($name_servers)
	{
		if (!empty($name_servers))
		{
			vy_name_server{ $name_servers :
				ensure => present
			}
		}
		if ($name_servers_mode==inclusive)
		{
			resources { 'vy_name_server':
				purge => true
			}
		}
	}
	
	case $pkg_repo_mode {
		'default':	{
		    vy_pkg_repo { 
		    'debian':
				ensure => present,
				url => 'http://ftp.debian.org/debian',
				distribution => 'squeeze',
				components => ['main','contrib','non-free'],
		    ;
		    'deb-security':
				ensure => present,
				url => 'http://security.debian.org',
				distribution => 'squeeze/updates',
				components => ['main','contrib','non-free'],
		    ;
		    'puppet':
				ensure => present,
				url => 'http://apt.puppetlabs.com',
				distribution => 'squeeze',
				components => 'main',
				pub_key => 'http://apt.puppetlabs.com/pubkey.gpg'
		    ;
		    'community':
				ensure => present,
				url => 'http://packages.vyatta.com/vyatta-dev/pacifica/unstable',
				distribution => 'pacifica',
				components => 'main'
			;
			}
			
			resources { 'vy_name_server':
				purge => true
			}
		}
		'minimum' : {
		    vy_pkg_repo { 
		    'debian':
				ensure => present,
				url => 'http://ftp.debian.org/debian',
				distribution => 'squeeze',
				components => ['main','contrib','non-free'],
		    ;
		    'deb-security':
				ensure => present,
				url => 'http://security.debian.org',
				distribution => 'squeeze/updates',
				components => ['main','contrib','non-free'],
		    ;
		    'puppet':
				ensure => present,
				url => 'http://apt.puppetlabs.com',
				distribution => 'squeeze',
				components => 'main',
				pub_key => 'http://apt.puppetlabs.com/pubkey.gpg'
		    ;
		    'community':
				ensure => present,
				url => 'http://packages.vyatta.com/vyatta-dev/pacifica/unstable',
				distribution => 'pacifica',
				components => 'main'
			;
			}
		}
	}
}
