package SeenTable;

use utf8;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my ($class) = @_;
    my $self = bless {
        -state => {},
        -loop => {},
    }, $class;
    return $self;
}

sub is_seen {
    my ($self, $state) = @_;
    return exists $self->{-state}->{$state};
}

sub add {
    my ($self, $loop, $state) = @_;
    unless (exists $self->{-loop}->{$loop}) {
        $self->{-loop}->{$loop} = 1;
        $self->{-state}->{$state} = 1;
    }
}

sub size_state { return scalar(%{$_[0]->{-state}}); }
sub size_loop { return scalar(%{$_[0]->{-loop}}); }

1;
