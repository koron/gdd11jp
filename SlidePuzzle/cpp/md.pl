#!/usr/bin/perl

use utf8;
use strict;
use warnings;

my @problems;

open IN, 'problems.txt' or die "$!\n";
<IN>; <IN>;
while (my $line = <IN>) {
    chomp $line;
    my ($col, $row, $s) = split ",", $line;
    my $final = &get_final($s);
    push @problems, {
        col => $col,
        row => $row,
        start => $s,
        final => $final,
        md => &get_md($s, $final, $col, $row),
        answer => '',
    };
}
close IN;

if (scalar(@ARGV) > 0 and -r $ARGV[0]) {
    open IN, $ARGV[0] or die "$!\n";
    my $lnum = 0;
    while (defined (my $line = <IN>) and $lnum < scalar(@problems)) {
        chomp $line;
        $problems[$lnum]->{answer} = $line;
        ++$lnum;
    }
    close IN;
}

my $i = 0;
foreach my $p (@problems) {
    printf("%d,%d,%d,%d,%d,%d\n", $i, $p->{col}, $p->{row},
        ($p->{col} * $p->{row}), $p->{md}, length($p->{answer}));
    ++$i;
}

sub get_final {
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

sub get_md {
    my ($s, $d, $col, $row) = @_;
    my @curr = split //, $s;
    my $md_sum = 0;
    for (my ($i, $N) = (0, scalar(@curr)); $i < $N; ++$i) {
        my $ch = $curr[$i];
        next if $ch eq '=' or $ch eq '0';
        my ($s_c, $s_r) = ($i % $col, int($i / $col));
        my $j = index $d, $ch;
        my ($d_c, $d_r) = ($j % $col, int($j / $col));
        my $md = abs($s_c - $d_c) + abs($s_r - $d_r);
        $md_sum += $md;
    }
    return $md_sum;
}
