use strict;

package MMDVM::TGControl::Timer;

use vars qw($VERSION);
#Define version
$VERSION = '0.1';

sub new {
    my($class) = shift;
    my($self) = {};
    bless($self,$class);
    return($self);
};

sub set_timer {
    my($self) = shift;
    my($minutes) = shift;
    $self->{_SECONDS} = $minutes * 60;
    $self->{_TIME} = time;
};

sub check_timer {
    my($self) = shift;
    if (time >= $self->{_TIME} + $self->{_SECONDS}) {
        $self->{_TIME} = time;
        return(1);
    } else {
        return(0);
    };
    
}

1;
