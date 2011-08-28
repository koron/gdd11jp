#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);

my $PROBLEMS = 'problems.txt';
my $ANSWERS = 'answers-1.txt';
my $OPT = 1;
my $TIMEOUT = 120;
my $ITEROUT = 1000000;

# Load problem file.
unlink $ANSWERS if -e $ANSWERS;
open IN, $PROBLEMS or die "$!\n";
<IN>; <IN>;
while (<IN>) {
    my $lnum = $.;
    chomp;
    my ($w, $h, $s) = split ",";
    my $answer = &compute_answer($w, $h, $s, $lnum);
    $answer = '' unless defined $answer;
    open OUT, ">>$ANSWERS" or die "$!\n";
    printf OUT "%s\n", $answer;
    close OUT;
}
close IN;
exit;

sub compute_answer {
    my ($w, $h, $s, $lnum) = @_;
    my $rank = $w * $h;
    my $answer;
    if ($rank <= 15) {
        # Compute for small size.
        my $start = gettimeofday();
        $answer = &solve_one($w, $h, $s);
        my $end = gettimeofday();
        printf "line %d in %f sec\n", $lnum, ($end - $start);
    } else {
        # TODO: compute some answers.
    }
    return $answer;
}

### from solve4-1.pl

sub solve_one {
    my ($w, $h, $s) = @_;
    my $puzzle = &new_puzzle($w, $h, $s);
    my $start = gettimeofday();
    my $answer = &solve_puzzle($puzzle, $start);
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
    my ($puzzle, $start) = @_;
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
        if ((gettimeofday() - $start) > $TIMEOUT) {
            print "  TIME OVER\n";
            last;
        } elsif ($count > $ITEROUT) {
            print "  ITERATION OVER\n";
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
                #printf "  Shrink height: %s\n", $hist.$d;
                my $puzzle2 = &new_puzzle($w, $h - 1, substr($next, $w));
                my $answer2 = &solve_puzzle($puzzle2, $start);
                undef $puzzle2;
                if (defined $answer2) {
                    return $hist.$d.$answer2;
                }
            }
            # Check width shrinkable.
            if ($shrinkable_width
                    and &get_head_col($w, $h, $next) eq $head_col)
            {
                #printf "  Shrink width: %s\n", $hist.$d;
                my $puzzle3 = &new_puzzle($w - 1, $h,
                    &remove_head_col($next, $w));
                my $answer3 = &solve_puzzle($puzzle3, $start);
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
