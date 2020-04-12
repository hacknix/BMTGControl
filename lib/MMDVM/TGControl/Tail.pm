use strict;

package MMDVM::TGControl::Tail;

use parent 'File::Tail::Inotify2';

=head1 NAME

MMDVM::TGControl::Tail;

=head1 SYNOPSIS

Extends File::Tail::Inotify2

=head1 AUTHOR

Simon (G7RZU) <simon@gb7fr.org.uk>

=cut

sub blocking {
    my($self) = shift;
    $self->{inotify}->blocking(shift);
}

sub poll_once {
    my $self = shift;
    $self->{inotify}->poll || $self->{in_move};
}

1;
