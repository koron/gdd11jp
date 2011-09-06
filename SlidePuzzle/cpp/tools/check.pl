#!/usr/bin/perl

use utf8;
use strict;
use warnings;

if (scalar(@ARGV) >= 2) {
    &check_all($ARGV[0], $ARGV[1]);
} else {
    print "USAGE: $0 {problem} {answer}\n";
}

sub check_all {
    my ($problem, $answer) = @_;

    open IN1, $problem or die "$!\n";
    open IN2, $answer or die "$!\n";

    <IN1>; <IN1>;
    my $num = 1;
    while (my $p = <IN1>) {
        $p =~ s/\s+$//;
        my $ans = <IN2>;
        $ans =~ s/\s+$// if defined $ans;

        my $result = 'NONE';
        my $msg;
        if (defined $ans and length($ans) > 0) {
            my $retval;
            ($retval, $msg) = &chekc_root($p, $ans);
            $result = $retval ? 'OK' : 'NG';
        }

        printf("#%-4d %s - %s\n", $num, $result, $p);
        if (defined $msg) {
            foreach my $m (@$msg) {
                printf("  %s\n", $m);
            }
        }
        ++$num;
    }

    close IN2;
    close IN1;
}

sub chekc_root {
    my ($problem, $root) = @_;

    my ($w, $h, $s) = split /,/, $problem;
    my $final = &get_final_status($s);

    my $pos = index $s, '0';
    for (my $i = 0; $i < length($root); ++$i) {
        if ($s eq $final) {
            return (0, [sprintf('reached goal at #%d', $i)]);
        }
        my $ch = substr($root, $i, 1);
        my $newpos;
        if ($ch eq 'L') {
            if (($pos % $w) > 0) {
                $newpos = $pos - 1;
            } else {
                return (0, [sprintf('over LEFT at #%d', $i)]);
            }
        } elsif ($ch eq 'R') {
            if (($pos % $w) < $w - 1) {
                $newpos = $pos + 1;
            } else {
                return (0, [sprintf('over RIGHT at #%d', $i)]);
            }
        } elsif ($ch eq 'U') {
            if ($pos >= $w) {
                $newpos = $pos - $w;
            } else {
                return (0, [sprintf('over UP at #%d', $i)]);
            }
        } elsif ($ch eq 'D') {
            if ($pos < $w * $h - $w) {
                $newpos = $pos + $w;
            } else {
                return (0, [sprintf('over UP at #%d', $i)]);
            }
        } else {
            return (0, [sprintf('unknown digit %s at #%d', $ch, $i)]);
        }
        if (substr($s, $newpos, 1) eq '=') {
            return (0, [sprintf('detect wall by %s at #%d', $ch, $i)]);
        }
        substr($s, $pos, 1, substr($s, $newpos, 1, '0'));
        $pos = $newpos;
    }
    if ($s ne $final) {
        return (0, ['unmatched', '  actually: '.$s, '  expected: '.$final]);
    } else {
        return 1;
    }
}

sub get_final_status {
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
