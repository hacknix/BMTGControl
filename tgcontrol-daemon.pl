#!/usr/bin/perl

#Don't buffer on STDOUT
$|++;

use strict;

BEGIN { push(@INC,'./lib/');};

use MMDVM::TGControl::Daemon;

sub main
{
# 	if ($ARGV[0] eq '-c')
# 	{
# 		require $ARGV[1];
# 	}
# 	else
# 	{
# 		require '/etc/tgcontrol-daemon.conf';
# 	};
	my($daemonobj) = MMDVM::TGControl::Daemon->new({
                    LOGFILE     =>  '/var/log/pi-star/MMDVM-2020-04-11.log',
                    DEFAULT_TG  =>  2350,
                    TIMEOUT     =>  600
            });
	die('No config hash passed, check config file.') if (!defined($daemonobj));
	$daemonobj->mainloop;
};
&main;
