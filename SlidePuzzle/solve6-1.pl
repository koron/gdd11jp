#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use Puzzle;
use Fixable;


#&solve('3,3,123456708');
#&solve('3,3,123456078');
#&solve('3,3,120743586');
#&solve('3,4,4127=36B89A0');
&solve('3,5,D42C7380915AB6E');

sub solve {
    my ($line) = @_;
    chomp $line;
    my ($w, $h, $s) = split /,/, $line;
    return &solve2($w, $h, $s, 1);
}

sub solve2 {
    my ($w, $h, $s, $verbose) = @_;
    my $puzzle = Puzzle->new($w, $h, $s);

    $puzzle->print_state(' -> START:', ' --- ') if $verbose;

    my $start = gettimeofday();
    my $answer = &solve_puzzle($puzzle);
    my $elapsed = gettimeofday() - $start;

    if (defined $answer) {
        printf " => Answer: %s\n", $answer if $verbose;
        printf " => Found in %f sec\n", $elapsed if $verbose;
    } else {
        printf " => Not found in %f sec\n", $elapsed if $verbose;
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
    my $shrinkable;
    #my $shrinkable = &get_shrinkable($puzzle);
    my $queue = [[$first_state, ' ']];
    my %seen;
    $seen{&get_state_hash($first_state)} = 0;

    my $raw_final = $puzzle->raw_final;
    return '' if $first_state eq $raw_final;

    my $step = 0;
    my @answers;

    my @shrinks;
    &check_shrinkable(\@shrinks, $shrinkable, $first_state, ' ', $raw_final);

    my ($WIDTH, $HEIGHT) = ($puzzle->width, $puzzle->height);
    while (scalar(@$queue) != 0
            and scalar(@answers) == 0
            and scalar(@shrinks) == 0)
    {
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

                &check_shrinkable(\@shrinks, $shrinkable, $next,
                    $new_moves, $raw_final);

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

    undef %seen;
    undef $queue;

    if (scalar(@answers) > 0) {
        print " -- Answers:\n";
        foreach (@answers) {
            printf " --- %s\n", $_;
        }
        return $answers[0];
    } elsif (scalar(@shrinks) > 0) {
        print " -- Shrinks:\n";
        foreach (@shrinks) {
            printf " --- %d %s '%s'\n", $_->[0], $_->[1], $_->[2];
        }
        my $first = $shrinks[0];
        substr $first->[1], $first->[0], 1, '=';
        my $subans = &solve2($puzzle->width, $puzzle->height, $first->[1], 1);
        return defined $subans ? $first->[2].$subans : undef;
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

sub get_shrinkable
{
    my ($puzzle) = @_;
    my $fixable = Fixable::get_fixable_table($puzzle->state);
    my $raw_state = '';
    for (my $row = 0; $row < $puzzle->height; ++$row) {
        $raw_state .= substr($fixable, $row * 8 + 9, $puzzle->width);
    }

    my $shrinkable = [];
    my $LAST = length($raw_state) - 1;
    for (my $i = 0; $i < $LAST; ++$i) {
        if (substr($raw_state, $i, 1) eq '1') {
            push @$shrinkable, $i;
        }
    }
    return $shrinkable;
}

sub check_shrinkable
{
    my ($shrinks, $shrinkable, $state, $moves, $final) = @_;
    return unless defined $shrinkable;

    foreach my $pos (@$shrinkable) {
        if (substr($state, $pos, 1) eq substr($final, $pos, 1)) {
            push @$shrinks, [$pos, $state, substr($moves, 1)];
        }
    }
}
