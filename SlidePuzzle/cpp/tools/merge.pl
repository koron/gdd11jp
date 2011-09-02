#!/usr/bin/perl

use utf8;
use strict;
use warnings;

open IN1, $ARGV[0] or die "$!\n";
open IN2, $ARGV[1] or die "$!\n";
while (my $line1 = <IN1>) {
    my $line2 = <IN2>;
    last unless defined $line2;
    chomp $line1;
    chomp $line2;
    if ($line1 ne '') {
        if ($line2 ne '' and length($line2) < length($line1)) {
            print $line2, "\n";
        } else {
            print $line1, "\n";
        }
    } else {
        print $line2, "\n";
    }
}
close IN2;
close IN1;
