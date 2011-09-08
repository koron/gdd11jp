#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);

use Puzzle;
use Route;
use LoopState;

&solve_route(
    '5,5,B234017==N6=KF5G=IDELMJOA',
    24,
    'UUUULLLLDDDDRRUURDDR',
    [ 6 ]
);

sub solve_route {
    my ($pstr, $start, $rstr, $spots) = @_;

    my $puzzle = Puzzle->new($pstr);

    my $array = &get_route_array($puzzle, $start, $rstr);
    my $route = Route->new($array, $spots);

    my $loop_curr = LoopState->new($puzzle->state, $route);
    my $loop_last = LoopState->new($puzzle->final, $route);

    # TODO:

    my $power = $loop_last->power($loop_curr);
    printf("power=%d\n", $power);

    #print Dumper($loop_curr);
    #print Dumper($loop_last);
}

sub get_route_array {
    my ($puzzle, $start, $route) = @_;
    my $array = [];
    my $pos = $start;
    foreach my $ch (split //, $route) {
        push @$array, $pos;
        $pos = $puzzle->move($pos, $ch);
        return undef if $pos < 0;
    }
    if ($pos != $start) {
        return undef;
    }
    return $array;
}
