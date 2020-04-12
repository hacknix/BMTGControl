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
                    LOGFILE     =>  '/var/exports/mmdvm/log',
                    DEFAULT_TG  =>  2350,
                    TIMEOUT     =>  1,
                    DAEMON      =>  1,
                    BM_APIKEY   =>  'oIp8qzFiT.vIrJ63.agTf.yPILicyCUWih2IRH$HGtn49u88Eo.UmxG1fZeOy6IQnKwbotT1Xe64IecjDbbZIR.YOcJjio7G6DSu4Iw@XC3CRgWrr4o7Wm2HzM.S85ve',
                    DMRID       =>  2342690
            });
	die('No config hash passed, check config file.') if (!defined($daemonobj));
	$daemonobj->mainloop;
};
&main;
