package LoopState;

use utf8;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my ($class, $pstr, $route) = @_;
    my $loop = '';
    foreach my $pos (@{$route->array}) {
        $loop .= substr($pstr, $pos, 1);
    }
    my $spot = '';
    foreach my $pos (@{$route->spots}) {
        $spot .= substr($pstr, $pos, 1);
    }
    return bless {
        -loop => $loop,
        -spot => $spot,
    }, $class;
}

sub _new {
    my ($class, $loop, $spot) = @_;
    return bless {
        -loop => $loop,
        -spot => $spot,
    }, $class;
}

sub spot {
    return defined $_[1] ? substr($_[0]->{-spot}, $_[1], 1) : $_[0]->{-spot};
}

sub loop {
    return defined $_[1] ? substr($_[0]->{-loop}, $_[1], 1) : $_[0]->{-loop};
}

sub power {
    my ($self, $other) = @_;
    my $power = 0;

    # Check 'loop'.
    (my $source = $self->loop) =~ s/0//;
    (my $target = $other->loop) =~ s/0//;
    my $index = index($target, substr($source, 0, 1));
    $target = substr($target, $index) . substr($target, 0, $index);

    my %pos;
    for (my ($i, $N) = (0, length($target)); $i < $N; ++$i) {
        $pos{substr($target, $i, 1)} = $i;
        #printf "  %s : %d\n", substr($target, $i, 1), $i;
    }
    for (my ($i, $N) = (0, length($self->spot)); $i < $N; ++$i) {
        $pos{$other->spot($i)} = $pos{$self->spot($i)} || 0;
    }

    #print "HERE: $source $target\n";
    for (my ($i, $N) = (0, length($source)); $i < $N; ++$i) {
        my $ex = $i + 1;
        my $ch = substr($source, $ex % $N, 1);
        my $ac = $pos{$ch};
        $ac += $N if $ac < $ex;
        $power += $ac - $ex;
        #printf("  %s: %d,%d -> %d\n", $ch, $ac, $ex, $ac - $ex);
    }


    # Check all 'spot'.
    for (my ($i, $N) = (0, length($self->spot)); $i < $N; ++$i) {
        my $ex = $self->spot($i);
        my $ac = $other->spot($i);
        if ($ac eq '0') {
            $power += 1;
        } elsif ($ac ne $ex) {
            $power += 2;
        }
    }

    return ($power, $target);
}

1;
