#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Time::HiRes;

&solve_all(\*STDIN);
exit;

sub solve_all {
    my ($IN) = @_;

    <$IN>;
    open OUT, '>answer.txt' or die "$!\n";
    my $no = 1;
    while (<$IN>) {
        my $line = <$IN>;
        last unless $line;
        my $lnum = $.;
        chomp $line;
        my @n = split(/ /, $line);
        my $time = 0;
        my $start = Time::HiRes::gettimeofday();
        my ($answer, $state) = &solve_one(\@n);
        my $end = Time::HiRes::gettimeofday();
        printf OUT "%d\n", $answer;
        printf("#%d (line %d) -> %d (in %f sec)\n",
            $no, $lnum, $answer, ($end - $start));
        ++$no;
    }
    close OUT;
}

sub solve_one {
    my ($array) = @_;

    for (my $i = 1; $i <= 21; ++$i) {
        #print "  $i\n";
        if (&find_answer($array, $i)) {
            return $i;
        }
    }
    return -1;
}

sub find_answer {
    my ($array, $len) = @_;
    if ($len <= 1) {
        return &apply_pattern($array, 0x01) == 0;
    } elsif ($len <= 2) {
        return &apply_pattern($array, 0x02) == 0;
    } else {
        my $N = 0x01 << ($len - 2);
        my $base = 0x02 << ($len - 2);
        for (my $i = 0; $i < $N; ++$i) {
            if (&apply_pattern($array, $base | $i) == 0) {
                return 1;
            }
        }
        return 0;
    }
}

sub apply_pattern {
    my ($array, $pattern) = @_;
    my @candidates = @$array;
    #printf "    %06X %s\n", $pattern, join(',', @candidates);
    for (; $pattern != 0; $pattern >>= 1) {
        if (($pattern & 1) == 1) {
            @candidates = grep { ($_ % 5) != 0; } @candidates;
            #printf "      5: %06X %s\n", $pattern, join(',', @candidates);
            return 0 if scalar(@candidates) == 0;
        } else {
            @candidates = map { $_ >> 1; } @candidates;
            #printf "      /: %06X %s\n", $pattern, join(',', @candidates);
        }
    }
    return length(@candidates);
}
