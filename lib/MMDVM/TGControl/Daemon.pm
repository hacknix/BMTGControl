BEGIN { push(@INC,'./lib/');}

use strict;

use Proc::Daemon;
#use LWP::ConsoleLogger::Everywhere ();
use Sys::Syslog qw(:DEFAULT setlogsock);

package MMDVM::TGControl::Daemon;

use vars qw($VERSION);
#Define version
$VERSION = '0.1';

sub new
{
	#Daemonise
	Proc::Daemon::Init;
	my($class) = shift;
	my($self) = shift;
	return(undef) unless (ref($self) =~ m/HASH/);
 	bless($self,$class);
    $GLOBAL::int = 0;
	Sys::Syslog::setlogsock('unix');
	Sys::Syslog::openlog('tgcontrol-daemon','ndelay,pid,cons', 'LOG_MAIL') or die('Cannot open syslog!');
	Sys::Syslog::syslog('info','Daemonic!');
	
	$self->{_BM_APIOBJ} = BrandMeister::API->new({
        BM_APIKEY   =>   'oIp8qzFiT.vIrJ63.agTf.yPILicyCUWih2IRH$HGtn49u88Eo.UmxG1fZeOy6IQnKwbotT1Xe64IecjDbbZIR.YOcJjio7G6DSu4Iw@XC3CRgWrr4o7Wm2HzM.S85ve',
        DMRID       => '235135',
    });
	
	return($self);
};

sub handle_int
{
	$GLOBAL::int++;
	Sys::Syslog::syslog('info','Caught signal:'.$_[0]."\n");
};

sub handle_hup
{
	$GLOBAL::checknow++;
	Sys::Syslog::syslog('info','Caught signal:'.$_[0]."\n");
};


sub bye
{
	Sys::Syslog::syslog('info','Exiting.');
	Sys::Syslog::closelog;
	exit(0);
};

sub mainloop {
	my($self) = shift;
	#Setup handlers
	$SIG{INT} = \&handle_int;
	$SIG{HUP} = \&handle_hup;
	$SIG{ABRT} = \&handle_int;
	$SIG{TERM} = \&handle_int;
	$SIG{QUIT} = \&handle_int;
	
	my($bmobj) = $self->{_BM_APIOBJ};
	
    chdir('/');
    
    while(1) {
    
        #Do stuff
        sleep(10);
        &bye if($GLOBAL::int);
    };
};
