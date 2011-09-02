#!/usr/bin/perl

use utf8;
use strict;
use warnings;

my %rank;
<>; <>;
while (<>) {
    chomp;
    my ($w, $h, $s) = split ",";
    $rank{$w * $h} += 1;
}
for (sort { $b <=> $a } keys %rank) {
    printf "%3d %5d\n", $_, $rank{$_};
}
