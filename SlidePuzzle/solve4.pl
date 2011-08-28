#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);
#my $puzzle = &new_puzzle(3, 3, '120743586');
my $puzzle = &new_puzzle(3, 3, '168452=30');
#my $puzzle = &new_puzzle(4,4, '41EC86079BA532FD');
my $start = gettimeofday();
my $answer = &solve_puzzle($puzzle);
my $end = gettimeofday();
if (defined $answer) {
    printf "answer=%s (in %f sec)\n", $answer, ($end - $start);
} else {
    print "Not found\n";
}

sub new_puzzle {
    my ($w, $h, $s) = @_;
    my $puzzle = {
        w => $w,
        h => $h,
        first => $s,
        final => &get_final($s),
        queue => [''],
        hash => {},
        moval => { 'U'=>-$w, L=>-1, R=>1, D=>$w },
    };
    return $puzzle;
}

sub solve_puzzle {
    my ($puzzle) = @_;
    my $count = 0;
    while (scalar(@{$puzzle->{queue}})) {
        my $move = shift @{$puzzle->{queue}};
        if ((++$count % 10000) == 0) {
            printf "  iterate %d\n", $count;
        }
        my $curr = &apply_move($puzzle, $move);
        #printf "%s %s\n", $curr, $move;
        if ($curr eq $puzzle->{final}) {
            return $move;
        } elsif (exists $puzzle->{hash}->{$curr}) {
            next;
        }
        $puzzle->{hash}->{$curr} = $move;
        my $movable = &get_movable($puzzle, $curr);
        foreach my $d (@$movable) {
            push @{$puzzle->{queue}}, $move.$d;
        }
    }
    return undef;
}

sub apply_move {
    my ($puzzle, $move) = @_;

    my @state = split //, $puzzle->{first};
    my $now = index $puzzle->{first}, '0';
    for my $d (split(//, $move)) {
        my $next = $now;
        if (exists $puzzle->{moval}->{$d}) {
            $next += $puzzle->{moval}->{$d};
        }
        @state[$now, $next] = @state[$next, $now];
        $now = $next;
    }
    return join('', @state);
}

sub get_movable {
    my ($puzzle, $curr) = @_;
    my $retval = [];

    my $pos = index $curr, '0';
    my $w = $puzzle->{w};
    my $x = $pos % $w;
    my $y = int($pos / $puzzle->{h});
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
