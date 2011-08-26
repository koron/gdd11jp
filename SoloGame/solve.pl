#!/usr/bin/perl

use utf8;
use strict;
use warnings;

sub solve_all {
    my ($IN) = @_;

    <$IN>;
    while (<$IN>) {
        my $line = <$IN>;
        last unless $line;
        chomp $line;
        my @n = split(/ /, $line);
        my $answer = &solve_one(\@n);
        printf "%d\n", $answer;
    }
}

sub solve_one {
    my ($array) = @_;
    for my $v (@$array) {
        my $bitmap = &get_bitmap($v);
        printf "    %8d: %s\n", $v, $bitmap;
        #my ($rank1, $rank2) = &get_rank($v);
        #my $start = $rank1;
        #my $end = $rank1 + $rank2;
        #my $over = ($v == 0) ? 0 : $rank1 + $rank2 + 3;
        #printf "    %6d : (%d,%d)->(%d,%d,%d)\n", $v, $rank1, $rank2, $start, $end, $over;
    }
    return 0;
}

sub get_bitmap {
    my ($value) = @_;
    my $retval = "";
    while ($value > 0) {
        if (($value % 5) == 0) {
            $retval .= '5';
        } else {
            $retval .= '/';
        }
        $value = int($value / 2);
    }
    $retval .= '.';
    return $retval;
}

sub get_rank {
    my ($value) = @_;
    my ($rank1, $rank2) = (0, 0);
    while (($value % 5) != 0) {
        $value = int($value / 2);
        ++$rank1;
    }
    if ($value > 0) {
        while (($value % 2) == 0) {
            $value = int($value / 2);
            ++$rank2;
        }
    }
    return ($rank1, $rank2);
}

&solve_all(\*STDIN);
