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
    my $target2 = '';
    for (my ($i, $N) = (0, length($self->spot)); $i < $N; ++$i) {
        my $ch = $other->spot($i);
        $pos{$ch} = $pos{$self->spot($i)} || 0;
        $target2 .= $ch;
    }

    #print "HERE: $source $target\n";
    for (my ($i, $N) = (0, length($source)); $i < $N; ++$i) {
        my $pivot = substr($source, $i, 1);
        my $ex = $pos{$pivot} + 1;
        my $ch = substr($source, ($i + 1) % $N, 1);
        my $ac = $pos{$ch};
        my $d = ($ex % $N) != $ac ? 1 : 0;
        $power += $d;
        #printf("  %s: %d,%d -> %d\n", $ch, $ac, $ex, $d);
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
