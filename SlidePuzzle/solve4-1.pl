#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);

#my $puzzle = &new_puzzle(3, 3, '120743586');
#my $puzzle = &new_puzzle(3, 3, '168452=30');
#my $puzzle = &new_puzzle(3, 4, '1365720A984B');
my $puzzle = &new_puzzle(3, 4, '4127=36B89A0');
#my $puzzle = &new_puzzle(3, 5, 'D42C7380915AB6E');
#my $puzzle = &new_puzzle(4, 4, '41EC86079BA532FD');
my $OPT = 1;

my $start = gettimeofday();
my $answer = &solve_puzzle($puzzle);
my $end = gettimeofday();
if (defined $answer) {
    printf "answer=%s (in %f sec)\n", $answer, ($end - $start);
} else {
    print "Not found\n";
}

sub solve_one {
    my ($w, $h, $s) = @_;
    my $puzzle = &new_puzzle($w, $h, $s);
    my $answer = &solve_puzzle($puzzle);
    undef $puzzle;
    return $answer;
}

sub new_puzzle {
    my ($w, $h, $s) = @_;
    my $puzzle = {
        w => $w,
        h => $h,
        first => $s,
        final => &get_final($s),
        queue => [$s],
        hash => { $s => '' },
    };
    return $puzzle;
}

sub solve_puzzle {
    my ($puzzle) = @_;
    my $count = 0;
    my $moval = {
        U => -$puzzle->{w},
        L => -1,
        R =>  1,
        D =>  $puzzle->{w},
    };
    my ($w, $h) = ($puzzle->{w}, $puzzle->{h});
    my $first = $puzzle->{first};
    my $shrinkable_height = 0;
    if ($OPT and $h > 2 and substr($first, $w + 1, 1) ne '='
            and substr($first, $w * 2 - 2) ne '=') {
        $shrinkable_height = 1;
    }
    my $shrinkable_width = 0;
    if ($OPT and $w > 2 and substr($first, $w + 1, 1) ne '='
            and substr($first, $w * ($h - 2) + 1) ne '=') {
        $shrinkable_width = 1;
    }
    my $head_row = substr($puzzle->{final}, 0, $puzzle->{w});
    my $head_col = &get_head_col($w, $h, $puzzle->{final});

    while (scalar(@{$puzzle->{queue}})) {
        if ((++$count % 100000) == 0) {
            printf "  iterate %d\n", $count;
        }
        if ($count > 1500000) {
            print "  OVER_ITER\n";
            last;
        }
        my $curr = shift @{$puzzle->{queue}};
        my $hist = $puzzle->{hash}->{$curr};
        my $movable = &get_movable($puzzle, $curr);
        foreach my $d (@$movable) {
            my $next = &apply_move2($moval, $curr, $d);
            if ($next eq $puzzle->{final}) {
                return $hist.$d;
            }
            # Check height shrinkable.
            if ($shrinkable_height and substr($next, 0, $w) eq $head_row) {
                printf "  Shrink height: %s\n", $hist.$d;
                my $puzzle2 = &new_puzzle($w, $h - 1, substr($next, $w));
                my $answer2 = &solve_puzzle($puzzle2);
                undef $puzzle2;
                if (defined $answer2) {
                    return $hist.$d.$answer2;
                }
            }
            # Check width shrinkable.
            if ($shrinkable_width
                    and &get_head_col($w, $h, $next) eq $head_col)
            {
                printf "  Shrink width: %s\n", $hist.$d;
                my $puzzle3 = &new_puzzle($w - 1, $h,
                    &remove_head_col($next, $w));
                my $answer3 = &solve_puzzle($puzzle3);
                undef $puzzle3;
                if (defined $answer3) {
                    return $hist.$d.$answer3;
                }
            }
            unless (exists $puzzle->{hash}->{$next}) {
                $puzzle->{hash}->{$next} = $hist.$d;
                push @{$puzzle->{queue}}, $next;
            }
        }
    }
    return undef;
}

sub apply_move2 {
    my ($moval, $s, $d) = @_;

    my @state = split //, $s;
    my $now = index $s, '0';
    my $next = $now;
    if (exists $moval->{$d}) {
        $next += $moval->{$d};
        @state[$now, $next] = @state[$next, $now];
    }

    return join('', @state);
}

sub get_movable {
    my ($puzzle, $curr) = @_;
    my $retval = [];

    my $pos = index $curr, '0';
    my $w = $puzzle->{w};
    my $x = $pos % $w;
    my $y = int($pos / $w);
    my @s = split //, $curr;

    if ($x > 0 and $s[$pos - 1] ne '=') {
        push @$retval, 'L';
    }
    if ($x < ($puzzle->{w} - 1) and $s[$pos + 1] ne '=') {
        push @$retval, 'R';
    }

    if ($y > 0 and $s[$pos - $w] ne '=') {
        push @$retval, 'U';
    }
    if ($y < ($puzzle->{h} - 1) and $s[$pos + $w] ne '=') {
        push @$retval, 'D';
    }

    return $retval;
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

sub get_head_col {
    my ($w, $h, $s) = @_;
    my $retval;
    for (my $i = 0; $i < length($s); $i += $w) {
        $retval .= substr($s, $i, 1);
    }
    return $retval;
}

sub remove_head_col {
    my ($s, $w) = @_;
    my $retval;
    for (my $i = 1; $i < length($s); $i += $w) {
        $retval .= substr($s, $i, $w - 1);
    }
    return $retval;
}
