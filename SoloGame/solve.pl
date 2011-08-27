#!/usr/bin/perl

use utf8;
use strict;
use warnings;

sub solve_all {
    my ($IN) = @_;

    <$IN>;
    while (<$IN>) {
        my $line = <$IN>;
        last unless $line;
        chomp $line;
        my @n = split(/ /, $line);
        my ($answer, $state) = &solve_one(\@n);
        #printf "%d\n", $answer;
        printf "%d :%s\n", $answer, $state;
    }
}

sub solve_one {
    my ($array) = @_;

    my @elements;
    my $max = 0;
    my $has5 = 0;
    my $no5min = 0;

    # Elementise.
    for my $v (@$array) {
        my $elem = &make_elem($v);
        push @elements, $elem;
        # Profiling #1.
        $max = $elem->{len} if $elem->{len} > $max;
        if ($elem->{has5}) {
            ++$has5;
        } else {
            if ($no5min <= 0 or $elem->{len} < $no5min) {
                $no5min = $elem->{len};
            }
        }
    }

    # Padding.
    foreach my $elem (@elements) {
        &pad_elem($elem, $max);
    }

    # Show status.
    foreach my $elem (@elements) {
        printf "  %8d: %s\n", $elem->{value}, $elem->{padmap};
    }
    printf "  max=%d has5=%d no5min=%d\n", $max, $has5, $no5min;

    if ($no5min == $max) {
        return ($no5min, 'NO5MIN');
    }

    if ($has5 == 0) {
        return ($max, 'ZERO5MAX');
    }

    # Check only one candidate.
    if (scalar(@elements) == 1) {
        my $rawmap = $elements[0]->{rawmap};
        my $first = index $rawmap, '5';
        if ($first >= 0) {
            return ($first + 1, 'SOLO_5');
        } else {
            return (length($rawmap), 'SOLO_MAX');
        }
    }

    if ($has5 < scalar(@elements)) {
        return (0, 'LESS5');
    } else {
        return (0, 'FULL5');
    }
}

sub make_elem {
    my ($value) = @_;
    my $rawmap = &get_bitmap($value);
    my $has5 = ($rawmap =~ /5/);
    return {
        value=>$value,
        len=>length($rawmap),
        rawmap=>$rawmap,
        padmap=>undef,
        has5=>$has5,
    };
}

sub pad_elem {
    my ($elem, $max) = @_;
    my $c = $max - $elem->{len};
    my $padmap;
    if ($c > 0) {
        $padmap = $elem->{rawmap} . ('.' x $c);
    } else {
        $padmap = $elem->{rawmap};
    }
    $padmap =~ s/...../$& /g;
    $elem->{padmap} = $padmap;
    return $elem;
}

sub get_bitmap {
    my ($value) = @_;
    my $retval = "";
    while ($value > 0) {
        if (($value % 5) == 0) {
            $retval .= '5';
        } else {
            $retval .= '/';
        }
        $value = int($value / 2);
    }
    $retval .= '.';
    return $retval;
}

sub get_rank {
    my ($value) = @_;
    my ($rank1, $rank2) = (0, 0);
    while (($value % 5) != 0) {
        $value = int($value / 2);
        ++$rank1;
    }
    if ($value > 0) {
        while (($value % 2) == 0) {
            $value = int($value / 2);
            ++$rank2;
        }
    }
    return ($rank1, $rank2);
}

&solve_all(\*STDIN);
