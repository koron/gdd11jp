#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use Puzzle;


#&solve_one('3,3,123456708');
#&solve_one('3,3,123456078');
#&solve_one('3,3,120743586');
#&solve_one('3,4,4127=36B89A0');
&solve_one('3,5,D42C7380915AB6E');

sub solve_one {
    my ($line) = @_;
    chomp $line;
    my ($w, $h, $s) = split /,/, $line;
    my $puzzle = Puzzle->new($w, $h, $s);

    $puzzle->print_state(' -> START:', ' --- ');

    my $start = gettimeofday();
    my $answer = &solve_puzzle($puzzle);
    my $elapsed = gettimeofday() - $start;

    if (defined $answer) {
        printf " => Answer: %s\n", $answer;
        printf " => Found in %f sec\n", $elapsed;
    } else {
        printf " => Not found in %f sec\n", $elapsed;
    }

    return $answer;
}

sub get_state_hash {
    my $s = $_[0];
    $s =~ s/=//g;
    return $s;
}

sub solve_puzzle {
    my ($puzzle) = @_;

    my $first_state = $puzzle->raw_state;
    my $queue = [[$first_state, ' ']];
    my %seen;
    $seen{&get_state_hash($first_state)} = 0;

    my $raw_final = $puzzle->raw_final;
    return '' if $first_state eq $raw_final;

    my $step = 0;
    my @answers;
    my ($WIDTH, $HEIGHT) = ($puzzle->width, $puzzle->height);
    while (scalar(@$queue) != 0 and scalar(@answers) == 0) {
        ++$step;
        my $next_queue = [];
        foreach my $curr (@$queue) {
            my $movable = &get_movable($WIDTH, $HEIGHT, $curr->[0],
                substr($curr->[1], -1, 1));
            foreach my $d (@$movable) {
                my $next = &apply_move($WIDTH, $HEIGHT, $curr->[0], $d);
                my $new_moves = $curr->[1].$d;
                if ($next eq $raw_final) {
                    push @answers, substr($new_moves, 1);
                    next;
                }
                my $hash = &get_state_hash($next);
                unless (exists $seen{$hash}) {
                    $seen{$hash} = $step;
                    push @$next_queue, [$next, $new_moves];
                }
            }
        }
        $queue = $next_queue;

        # TODO: Check size of seen and queue.
        printf("Step #%d: queue=%d seen=%s\n",
            $step, scalar(@$queue), scalar(%seen));
    }
    if (scalar(@answers) > 0) {
        print " -- Answers:\n";
        foreach (@answers) {
            printf " --- %s\n", $_;
        }
        return $answers[0];
    } else {
        return undef;
    }
}

sub get_movable {
    my ($w, $h, $curr, $prev) = @_;

    my $pos = index $curr, '0';
    my $x = $pos % $w;
    my $y = int($pos / $w);

    my $retval = [];
    if ($prev ne 'D' and $y > 0 and substr($curr, $pos - $w, 1) ne '=') {
        push @$retval, 'U';
    }
    if ($prev ne 'R' and $x > 0 and substr($curr, $pos - 1, 1) ne '=') {
        push @$retval, 'L';
    }
    if ($prev ne 'L' and $x < $w - 1 and substr($curr, $pos + 1, 1) ne '=') {
        push @$retval, 'R';
    }
    if ($prev ne 'U' and $y < $h - 1 and substr($curr, $pos + $w, 1) ne '=') {
        push @$retval, 'D';
    }

    return $retval;
}

sub apply_move {
    my ($w, $h, $curr, $d) = @_;
    my $old_pos = index($curr, '0');
    my $new_pos = $old_pos + (
        $d eq 'U' ? -$w :
        $d eq 'L' ? -1 :
        $d eq 'R' ? +1 :
        $d eq 'D' ? +$w : 0);
    substr($curr, $old_pos, 1, substr($curr, $new_pos, 1, '0'));
    return $curr;
}
