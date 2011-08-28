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
my $num = 0;
my $total = 0;

while (<>) {
    chomp;
    ++$num if length > 0;
    ++$total;
    for my $ch (split //) {
        $count{$ch} += 1;
    }
}

for (@order) {
    my $c = $count{$_};
    my $l = $limit{$_};
    printf "%s: %5d/%5d (%.2f%%)\n", $_, $c, $l, ($c * 100 / $l);
}

print "\n";
printf "TOTAL: %4d/%4d (%.2f%%)\n", $num, $total, ($num * 100 / $total);
