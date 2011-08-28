#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);

my $PROBLEMS = 'problems.txt';
my $ANSWERS = 'answers.txt';
my $ANSWERS_NEW = 'answers.txt.new';
my $ANSWERS_OLD = 'answers.txt.old';

my @boards;
my @answers;

# Load problem file.
open IN, $PROBLEMS or die "$!\n";
<IN>; <IN>;
while (<IN>) {
    my $lnum = $.;
    chomp;
    my ($w, $h, $s) = split ",";
    push @boards, &new_board($w, $h, $s, $lnum);
}
close IN;

# Compute some answers.
for (my ($i, $N) = (0, scalar(@boards)); $i < $N; ++$i) {
    my $answer = &compute_answer($boards[$i]);
    if (defined $answer and length($answer) >= 0) {
        $answer =~ tr/\n//;
        $answers[$i] = $answer;
    }
}

# Update answer file.
open OUT, ">$ANSWERS_NEW" or die "$!\n";
binmode OUT;
if (-f $ANSWERS) {
    open IN, $ANSWERS or die "$!\n";
    for (my ($i, $N) = (0, scalar(@boards)); $i < $N; ++$i) {
        my $old = <IN>;
        chomp $old;
        if (defined $answers[$i]) {
            print OUT "$answers[$i]\n";
        } else {
            print OUT "$old\n";
        }
    }
    close IN;
} else {
    for (my ($i, $N) = (0, scalar(@boards)); $i < $N; ++$i) {
        if (defined $answers[$i]) {
            print OUT "$answers[$i]\n";
        } else {
            print OUT "\n";
        }
    }
}
close OUT;
if (-e $ANSWERS_NEW) {
    rename $ANSWERS, $ANSWERS_OLD if -e $ANSWERS;
    rename $ANSWERS_NEW, $ANSWERS;
    unlink $ANSWERS_OLD if -e $ANSWERS_OLD;
}
exit;

sub print_board {
    my ($w, $h, $board, $name) = @_;
    my $idx = 0;
    printf "%s:\n", $name if defined $name;
    for (my $i = 0; $i < $h; ++$i) {
        printf "    %s\n", (substr $board, $idx, $w);
        $idx += $w;
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

sub new_board
{
    my ($w, $h, $s, $lnum) = @_;
    (my $wallnum = $s) =~ s/[^=]//g;
    return {
        w=>$w,
        h=>$h,
        s=>$s,
        rank=>($w * $h),
        wallnum=>length($wallnum),
        lnum => $lnum,
    };
}

sub print_board2 {
    my ($board, $name) = @_;
    &print_board($board->{w}, $board->{h}, $board->{s}, $name);
}

sub compute_answer {
    my ($board) = @_;
    my $answer;

    if ($board->{rank} <= 9) {
        # Compute for small size.
        my $start = gettimeofday();
        $answer = &solve_one($board->{w}, $board->{h}, $board->{s});
        my $end = gettimeofday();
        printf "line %d in %f sec\n", $board->{lnum}, ($end - $start);
    } else {
        # TODO: compute some answers.
    }

    return $answer;
}

### from solve4.pl

sub solve_one {
    my ($w, $h, $s) = @_;
    my $puzzle = &new_puzzle($w, $h, $s);
    return &solve_puzzle($puzzle);
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
    while (scalar(@{$puzzle->{queue}})) {
        if ((++$count % 100000) == 0) {
            printf "  iterate %d\n", $count;
        }
        my $curr = shift @{$puzzle->{queue}};
        my $hist = $puzzle->{hash}->{$curr};
        my $movable = &get_movable($puzzle, $curr);
        foreach my $d (@$movable) {
            my $next = &apply_move2($moval, $curr, $d);
            if ($next eq $puzzle->{final}) {
                return $hist.$d;
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
