#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);
#my $puzzle = &new_puzzle(3, 3, '120743586');
#my $puzzle = &new_puzzle(3, 3, '168452=30');
#my $puzzle = &new_puzzle(3, 4, '1365720A984B');
#my $puzzle = &new_puzzle(3, 4, '4127=36B89A0');
my $puzzle = &new_puzzle(3, 5, 'D42C7380915AB6E');
#my $puzzle = &new_puzzle(4, 4, '41EC86079BA532FD');
my $start = gettimeofday();
my $answer = &solve_puzzle($puzzle);
my $end = gettimeofday();
if (defined $answer) {
    printf "answer=%s (in %f sec)\n", $answer, ($end - $start);
} else {
    print "Not found\n";
}

sub solve_one {
    my ($w, $h, $s) = @_;
    my $puzzle = &new_puzzle($w, $h, $s);
    return &solve_puzzle($puzzle);
}

sub new_puzzle {
    my ($w, $h, $s) = @_;
    my $puzzle = {
        w => $w,
        h => $h,
        first => $s,
        final => &get_final($s),
        queue => [$s],
        hash => { $s => '' },
    };
    return $puzzle;
}

sub solve_puzzle {
    my ($puzzle) = @_;
    my $count = 0;
    my $moval = {
        U => -$puzzle->{w},
        L => -1,
        R =>  1,
        D =>  $puzzle->{w},
    };
    while (scalar(@{$puzzle->{queue}})) {
        if ((++$count % 100000) == 0) {
            printf "  iterate %d\n", $count;
        }
        my $curr = shift @{$puzzle->{queue}};
        my $hist = $puzzle->{hash}->{$curr};
        my $movable = &get_movable($puzzle, $curr);
        foreach my $d (@$movable) {
            my $next = &apply_move2($moval, $curr, $d);
            if ($next eq $puzzle->{final}) {
                return $hist.$d;
            }
            unless (exists $puzzle->{hash}->{$next}) {
                $puzzle->{hash}->{$next} = $hist.$d;
                push @{$puzzle->{queue}}, $next;
            }
        }
    }
    return undef;
}

sub apply_move2 {
    my ($moval, $s, $d) = @_;

    my @state = split //, $s;
    my $now = index $s, '0';
    my $next = $now;
    if (exists $moval->{$d}) {
        $next += $moval->{$d};
        @state[$now, $next] = @state[$next, $now];
    }

    return join('', @state);
}

sub get_movable {
    my ($puzzle, $curr) = @_;
    my $retval = [];

    my $pos = index $curr, '0';
    my $w = $puzzle->{w};
    my $x = $pos % $w;
    my $y = int($pos / $w);
    my @s = split //, $curr;

    if ($x > 0 and $s[$pos - 1] ne '=') {
        push @$retval, 'L';
    }
    if ($x < ($puzzle->{w} - 1) and $s[$pos + 1] ne '=') {
        push @$retval, 'R';
    }

    if ($y > 0 and $s[$pos - $w] ne '=') {
        push @$retval, 'U';
    }
    if ($y < ($puzzle->{h} - 1) and $s[$pos + $w] ne '=') {
        push @$retval, 'D';
    }

    return $retval;
}

sub get_final {
    my ($first) = @_;

    (my $numbers = $first) =~ s/[=0]//g;
    my @numbers = sort split //, $numbers;
    push @numbers, '0';

    my @final;

    (my $walls = $first) =~ s/[^=]/./g;
    for my $ch (split(//, $walls)) {
        if ($ch eq '.') {
            $ch = shift @numbers;
        }
        push @final, $ch;
    }

    return join('', @final);
}
