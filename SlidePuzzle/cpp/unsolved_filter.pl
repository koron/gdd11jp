#!/usr/bin/perl

use utf8;
use strict;
use warnings;

if (scalar(@ARGV) >= 2) {
    &unsolved_filter($ARGV[0], $ARGV[1]);
} else {
    print "USAGE: $0 [problem] [answer]\n";
}

sub unsolved_filter {
    my ($problem, $answer) = @_;

    open IN1, $problem or die "$!\n";
    open IN2, $answer or die "$!\n";

    my $first = <IN1>; print $first;
    my $second = <IN1>; print $second;
    while (my $p = <IN1>) {
        chomp $p;
       my $ans = <IN2>;
       chomp $ans;
       if (not defined $ans or length($ans) == 0) {
           print "$p\n";
       } else {
           print "\n";
       }
    }

    close IN2;
    close IN1;
}
