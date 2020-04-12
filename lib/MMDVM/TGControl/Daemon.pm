BEGIN { push(@INC,'./lib/');}

use strict;

use Proc::Daemon;
#use LWP::ConsoleLogger::Everywhere ();
use Sys::Syslog qw(:DEFAULT setlogsock);
use MMDVM::TGControl::Tail;
use BrandMeister::API;

package MMDVM::TGControl::Daemon;

use vars qw($VERSION);
#Define version
$VERSION = '0.1';

sub new
{
	#Daemonise
#	Proc::Daemon::Init;
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
        DMRID       => '2342690',
    });
    $MMDVM::TGControl::Daemon::self = $self;
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

sub work {
    my($self) = $MMDVM::TGControl::Daemon::self;
    #print log for testing
    $self->do_work(shift);
    &bye if($GLOBAL::int);
};

sub do_work {
    my($self) = shift;
    my($line) = shift;
    my($bmobj) = $self->{_BM_APIOBJ};
    my($slot,$call,$tg,$res,$jsonres);
    $self->{_CURRENT_TG} = 0;
    chomp($line);
    if ($line =~ m/^.+DMR\WSlot\W(\d),\Wreceived\WRF\Wvoice\Wheader\Wfrom\W(\w+)\Wto\WTG\W(\d+)$/) {
            print("Match\n");
            $slot = $1;
            $call = $2;
            $tg = $3;
    
        #only operate on slot 2
        return if ($slot != 2);
        
        Sys::Syslog::syslog('info','Matched Slot '.$slot.' '.$call.' to TG '.$tg);
        
        $res = $bmobj->dropdynamic($slot);
        if ($res) {
        Sys::Syslog::syslog('info','Dynamic mappings not dropped - LWP returned an error: '.$bmobj->result);  
        return;
        };
        $jsonres = $bmobj->json_response;
        if ($$jsonres{code} eq 'OKSTAY') {
        Sys::Syslog::syslog('info','Dynamic mappings dropped'); 
        } else {
        Sys::Syslog::syslog('info','Dynamic mappings not dropped - BM API server returned an error: '.$$jsonres{code}); 
        };
        
        if ($self->{_CURRENT_TG} ne 0) {
            $res = $bmobj->del_static_tg($slot,$self->{_CURRENT_TG});
            if ($res) {
                Sys::Syslog::syslog('info','Previous static not dropped - LWP returned an error: '.$bmobj->result);  
                return;
            };
            $jsonres = $bmobj->json_response;
            if ($$jsonres{code} eq 'OK') {
                Sys::Syslog::syslog('info','Previous static dropped'); 
            } else {
                Sys::Syslog::syslog('info','Previous static not dropped - BM API server returned an error: '.$$jsonres{code}); 
            }; 
        };
        
        $res = $bmobj->add_static_tg($slot,$tg);
        if ($res) {
        Sys::Syslog::syslog('info','Static TG not added - LWP returned an error: '.$bmobj->result);  
        return;
        };
        $jsonres = $bmobj->json_response;
        if ($$jsonres{code} eq 'OK') {
        Sys::Syslog::syslog('info','Static TG Added'); 
        } else {
        Sys::Syslog::syslog('info','Static TG not added - BM API server returned an error: '.$$jsonres{code}); 
        }; 
    
        $self->{_CURRENT_TG} = $tg;
    };
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

    my($filename) = $self->{LOGFILE};
    my($watcher) = MMDVM::TGControl::Tail->new(
        file    => $filename,
        on_read => \&work
    );
    $watcher->poll;      
};
