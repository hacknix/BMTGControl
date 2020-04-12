BEGIN { push(@INC,'./lib/');}

use strict;

use Proc::Daemon;
#use LWP::ConsoleLogger::Everywhere ();
use Sys::Syslog qw(:DEFAULT setlogsock);
use MMDVM::TGControl::Tail;
use MMDVM::TGControl::Timer;
use BrandMeister::API;

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
	_log('Daemonic!');
	
	$self->{_BM_APIOBJ} = BrandMeister::API->new({
        BM_APIKEY   =>  $self->{BM_APIKEY},
        DMRID       =>  $self->{DMRID},
    });
    $MMDVM::TGControl::Daemon::self = $self;
	return($self);
};

sub handle_int
{
	$GLOBAL::int++;
	_log('Caught signal:'.$_[0]."\n");
};

sub handle_hup
{
	$GLOBAL::defaultnow++;
	_log('Caught signal:'.$_[0]."\n");
};


sub bye
{
	_log('Exiting.');
	Sys::Syslog::closelog;
	exit(0);
};

sub _log {
    my($self) = $MMDVM::TGControl::Daemon::self;
    my($line) = shift;
    if ($self->{DAEMON}) {
        Sys::Syslog::syslog('info',$line);
    } else {
        print($line."\n");
    };
};

sub _work {
    my($self) = $MMDVM::TGControl::Daemon::self;
    $self->_do_work(shift);
    &bye if($GLOBAL::int);
};

sub _do_work {
    my($self) = shift;
    my($line) = shift;
    my($bmobj) = $self->{_BM_APIOBJ};
    my($slot,$call,$tg,$res,$jsonres);
    $self->{_CURRENT_TG} = 0;
    chomp($line);
    if (($line =~ m/^.+DMR\WSlot\W(\d),\Wreceived\WRF\Wvoice\Wheader\Wfrom\W(\w+)\Wto\WTG\W(\d+)$/) && ($self->{_CURRENT_TG} != $3)) {
            $slot = $1;
            $call = $2;
            $tg = $3;
    
        #only operate on slot 2
        return if ($slot != 2);
        
        _log('Matched Slot '.$slot.' '.$call.' to TG '.$tg);
        
        $res = $bmobj->dropdynamic($slot);
        if ($res) {
        _log('Dynamic mappings not dropped - LWP returned an error: '.$bmobj->result);  
        return;
        };
        $jsonres = $bmobj->json_response;
        if (ref($jsonres) eq "HASH" && $$jsonres{code} eq 'OKSTAY') {
        _log('Dynamic mappings dropped'); 
        } else {
        _log('Dynamic mappings not dropped - BM API server returned an error: '.$$jsonres{code}); 
        };
        
        if ($self->{_CURRENT_TG} != 0) {
            $res = $bmobj->del_static_tg($slot,$self->{_CURRENT_TG});
            if ($res) {
                _log('Previous static not dropped - LWP returned an error: '.$bmobj->result);  
                return;
            };
            $jsonres = $bmobj->json_response;
            if (ref($jsonres) eq "HASH" && $$jsonres{code} eq 'OK') {
                _log('Previous static dropped'); 
            } else {
                _log('Previous static not dropped - BM API server returned an error: '.$$jsonres{code}); 
            }; 
        };
        
        $res = $bmobj->add_static_tg($slot,$tg);
        if ($res) {
        _log('Static TG not added - LWP returned an error: '.$bmobj->result);  
        return;
        };
        $jsonres = $bmobj->json_response;
        if (ref($jsonres) eq "HASH" && $$jsonres{code} eq 'OK') {
        _log('Static TG Added'); 
        } else {
        _log('Static TG not added - BM API server returned an error: '.$$jsonres{code}); 
        }; 
    
        $self->{_CURRENT_TG} = $tg;
        
        $self->{_TIMER_OBJ}->set_timer($self->{TIMEOUT});
        
    };
};

sub default {
    my($self) = shift;
    my($bmobj) = $self->{_BM_APIOBJ};
    my($slot,$tg,$res,$jsonres);
    
    $slot = 2;
    $tg = $self->{DEFAULT_TG};
    
    if ($self->{_CURRENT_TG} != 0) {
    $res = $bmobj->del_static_tg($slot,$self->{_CURRENT_TG});
        if ($res) {
            _log('Previous static not dropped - LWP returned an error: '.$bmobj->result);  
            return;
        };
        $jsonres = $bmobj->json_response;
        if (ref($jsonres) eq "HASH" && $$jsonres{code} eq 'OK') {
            _log('Previous static dropped'); 
        } else {
            _log('Previous static not dropped - BM API server returned an error: '.$jsonres); 
        }; 
    };
    
    $res = $bmobj->add_static_tg($slot,$tg);
    if ($res) {
    _log('Static TG not added - LWP returned an error: '.$bmobj->result);  
    return;
    };
    $jsonres = $bmobj->json_response;
    if (ref($jsonres) eq "HASH" && $$jsonres{code} eq 'OK') {
        _log('Static TG Added'); 
    } else {
        _log('Static TG not added - BM API server returned an error: '.$$jsonres{code}); 
    }; 
    
        $self->{_CURRENT_TG} = $tg;
 
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
        on_read => \&_work
    );
    
    $watcher->blocking(0);
    
    $self->{_TIMER_OBJ} = MMDVM::TGControl::Timer->new();
    
    $self->default();
    
    while (1) {
        $watcher->poll_once;  
        
        if ($self->{_TIMER_OBJ}->check_timer() && ($self->{_CURRENT_TG} != $self->{DEFAULT_TG})) {
            $self->default();
        }
        
        if ($GLOBAL::defaultnow) {
            $self->default();
            $GLOBAL::defaultnow = 0;
        }
        
        &bye if ($GLOBAL::int);
        sleep(1);
    };
};
