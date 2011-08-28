#!/usr/bin/perl

use utf8;
use strict;
use warnings;

my %count;
my %limit = (
    L => 72187,
    R => 81749,
    U => 72303,
    D => 81778,
);
my @order = qw(L R U D);
while (<>) {
    chomp;
    for my $ch (split //) {
        $count{$ch} += 1;
    }
}

for (@order) {
    my $c = $count{$_};
    my $l = $limit{$_};
    printf "%s: %5d/%5d (%.2f%%)\n", $_, $c, $l, ($c * 100 / $l);
}
