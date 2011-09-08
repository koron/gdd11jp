#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);

use Puzzle;
use Route;
use LoopState;
use Step;

my $answer = &solve_route(
    '5,5,B234017==N6=KF5G=IDELMJOA',
    24,
    'UUUULLLLDDDDRRUURDDR',
    [ 6 ]
);
printf("ANSWER: %s\n", $answer);

sub solve_route {
    my ($pstr, $start, $rstr, $spots) = @_;

    my $puzzle = Puzzle->new(split(/,/, $pstr));

    my $route = Route->new(&get_route_array($puzzle, $start, $rstr), $spots);
    my $basement = LoopState->new($puzzle->final, $route);

    # Cutting branches woking area.
    my ($min_power) = &get_power($puzzle->state, $route, $basement);
    my %seen_state;
    my %seen_loop;
    my $pivot_time = gettimeofday() + 1;

    my $count = 0;
    my @steps = (Step->new('', $puzzle, $puzzle->state));
    while (scalar(@steps) > 0) {
        my $tail = $steps[-1];
        my $next = $tail->next;
        unless ($next) {
            pop @steps;
            next;
        }

        # Check goal or seen.
        if ($next->state eq $puzzle->final) {
            return join('', map { $_->moved; } @steps);
        }

        # Calculate power (distance) info.
        my ($power, $loop) = &get_power($next->state, $route, $basement);
        if ($power > $min_power or exists $seen_state{$next->state}) {
            next;
        }

        # Reset seen state when power is advaced.
        if ($power < $min_power) {
            printf("  Power down %d->%d at %d\n", $min_power, $power, $count);
            $min_power = $power;
            %seen_state = ();
            %seen_loop = ();
            my $p2 = Puzzle->new($puzzle->w, $puzzle->h, $next->state);
            $p2->print_state(undef, "    ");
        }

        unless (exists $seen_loop{$loop}) {
            $seen_loop{$loop} = 1;
            $seen_state{$next->state} = 1;
        }

        ++$count;
        push @steps, $next;

        if ((my $now = gettimeofday()) > $pivot_time) {
            printf("  (Steps:%d State:%s Loop:%s)\n",
                scalar(@steps), scalar(%seen_state), scalar(%seen_loop));
            $pivot_time = $now + 1;
        }

        if (($count % 100000) == 0) {
            #print Dumper(\@steps);
            printf("power=%d\n", $power);
            printf("expect_loop=%s\n", substr($basement->loop, 1));
            printf("actual_loop=%s\n", $loop);
            exit;
        }
    }

    return undef;
}

sub get_power {
    my ($state, $route, $basement) = @_;
    my $curr = LoopState->new($state, $route);
    return $basement->power($curr);
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
