#!/usr/bin/perl

use utf8;
use strict;
use warnings;

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
    chomp;
    my ($w, $h, $s) = split ",";
    push @boards, &new_board($w, $h, $s);
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
    my ($w, $h, $s) = @_;
    (my $wallnum = $s) =~ s/[^=]//g;
    return {
        w=>$w,
        h=>$h,
        s=>$s,
        rank=>($w * $h),
        wallnum=>length($wallnum),
    };
}

sub print_board2 {
    my ($board, $name) = @_;
    &print_board($board->{w}, $board->{h}, $board->{s}, $name);
}

sub compute_answer {
    my ($board) = @_;
    my $answer;
    # TODO: compute some answers.
    return $answer;
}
