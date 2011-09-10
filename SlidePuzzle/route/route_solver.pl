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

# USAGE SAMPLE:
#   $ perl route_solver.pl [MOVES] < q/2901.txt

if (defined $ARGV[0]) {
    &Step::set_move_type($ARGV[0] + 0);
}

while (<STDIN>) {
    s/\s+$//;
    &solve_route2($_);
}

sub solve_route2 {
    my ($str) = @_;
    my ($name, $pstr, $start, $rstr, $spots) = split / /, $str;
    my $ans = &solve_route($pstr, $start + 0, $rstr, [split /,/, $spots]);
    $ans ||= '';
    my @checks = &check_root($pstr, $ans);
    printf("RESULT:%s:%s:%d:%s\n", $name, $ans, length($ans),
        ($checks[0] ? "OK" : "NG"));
    return $ans;
}

sub solve_route {
    my ($pstr, $start, $rstr, $spots) = @_;

    my $puzzle = Puzzle->new(split(/,/, $pstr));

    my $route = Route->new(&get_route_array($puzzle, $start, $rstr), $spots);
    my $basement = LoopState->new($puzzle->final, $route);

    # Cutting branches woking area.
    my $pivot_time = gettimeofday() + 1;

    my $count = 0;
    my $first_step = Step->new('', $puzzle, $puzzle->state,
        &get_power($puzzle->state, $route, $basement));
    my @steps = ($first_step);
    while (scalar(@steps) > 0) {
        my $tail = $steps[-1];
        my $next = $tail->next;

        # Backtrack.
        unless ($next) {
            pop @steps;
            next;
        }

        # Check goal or seen.
        if ($next->state eq $puzzle->final) {
            push @steps, $next;
            return join('', map { $_->moved; } @steps);
        }

        # Calculate power (distance) info.
        my ($power, $loop) = &get_power2($next->state, $route, $basement);
        if ($power > $next->min_power or $next->seen->is_seen($next->state)) {
            next;
        }

        # Reset seen state when power is advaced.
        if ($power < $next->min_power) {
            printf("  Power down %d->%d at %d (%s)\n",
                $next->min_power, $power, $count, $loop);
            $next->min_power($power);
            $next->seen(SeenTable->new());
            #my $p2 = Puzzle->new($puzzle->w, $puzzle->h, $next->state);
            #$p2->print_state(undef, "    ");
        }

        $next->seen->add($loop, $next->state);

        ++$count;
        push @steps, $next;

        if ((my $now = gettimeofday()) > $pivot_time) {
            printf("  (Steps:%d State:%s Loop:%s)\n", scalar(@steps),
                $next->seen->size_state, $next->seen->size_loop);
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
    my @retvals = &get_power2($state, $route, $basement);
    return $retvals[0];
}

sub get_power2 {
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

sub check_root {
    my ($problem, $root) = @_;

    my ($w, $h, $s) = split /,/, $problem;
    my $final = &get_final_status($s);

    my $pos = index $s, '0';
    for (my $i = 0; $i < length($root); ++$i) {
        if ($s eq $final) {
            return (0, [sprintf('reached goal at #%d', $i)]);
        }
        my $ch = substr($root, $i, 1);
        my $newpos;
        if ($ch eq 'L') {
            if (($pos % $w) > 0) {
                $newpos = $pos - 1;
            } else {
                return (0, [sprintf('over LEFT at #%d', $i)]);
            }
        } elsif ($ch eq 'R') {
            if (($pos % $w) < $w - 1) {
                $newpos = $pos + 1;
            } else {
                return (0, [sprintf('over RIGHT at #%d', $i)]);
            }
        } elsif ($ch eq 'U') {
            if ($pos >= $w) {
                $newpos = $pos - $w;
            } else {
                return (0, [sprintf('over UP at #%d', $i)]);
            }
        } elsif ($ch eq 'D') {
            if ($pos < $w * $h - $w) {
                $newpos = $pos + $w;
            } else {
                return (0, [sprintf('over UP at #%d', $i)]);
            }
        } else {
            return (0, [sprintf('unknown digit %s at #%d', $ch, $i)]);
        }
        if (substr($s, $newpos, 1) eq '=') {
            return (0, [sprintf('detect wall by %s at #%d', $ch, $i)]);
        }
        substr($s, $pos, 1, substr($s, $newpos, 1, '0'));
        $pos = $newpos;
    }
    if ($s ne $final) {
        return (0, ['unmatched', '  actually: '.$s, '  expected: '.$final]);
    } else {
        return (1);
    }
}

sub get_final_status {
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
