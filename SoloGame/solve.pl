#!/usr/bin/perl

use utf8;
use strict;
use warnings;

my $DEBUG = 1;

sub solve_all {
    my ($IN) = @_;

    <$IN>;
    while (<$IN>) {
        my $line = <$IN>;
        last unless $line;
        chomp $line;
        my @n = split(/ /, $line);
        my ($answer, $state) = &solve_one(\@n);
        if ($DEBUG) {
            printf "%d :%s\n", $answer, $state;
        } else {
            printf "%d\n", $answer;
        }
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

    # Calc sum of "AND".
    my $andsum = &and_all(\@elements);

    # Show status.
    foreach my $elem (@elements) {
        printf("  %8d: %s (%08X)\n", $elem->{value}, $elem->{padmap},
            $elem->{padval});
    }
    printf("  cnt=%d max=%d has5=%d no5min=%d andsum=%08X\n",
        scalar(@elements), $max, $has5, $no5min, $andsum);

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
        return &solve_less5(\@elements);
    } else {
        return &solve_full5(\@elements);
    }
}

sub solve_less5 {
    my ($array) = @_;
    my ($array1, $array2) = ([], []);

    my $max_no5 = 0;
    foreach my $item (@$array) {
        if ($item->{has5}) {
            push @$array2, $item;
        } else {
            push @$array1, $item;
            if ($item->{len} > $max_no5) {
                $max_no5 = $item->{len};
            }
        }
    }

    my ($answer, $status) = &solve_full5($array2);

    if ($answer > $max_no5) {
        return ($answer, 'LESS5_'.$status);
    } else {
        return ($max_no5, 'LESS5');
    }
}

sub solve_full5 {
    my ($array) = @_;

    my $maxlen = &max_len($array);

    # Found solid answer.
    my $andsum = &and_all($array);
    printf "  andsum=%08X\n", $andsum;
    my $min1 = 0;
    for (my $i = 1; $andsum > 0 and $i <= 32; ++$i) {
        if (($andsum & 1) != 0) {
            $min1 = $i;
            last;
        }
        $andsum >>= 1;
    }

    # FIXME: Not perfect.  But enough for current inputs.
    if ($min1 > 0 and $min1 < $maxlen) {
        return ($min1, 'FULL5_MIN1');
    }

    # TODO:

    return (999, 'FULL5_TODO');
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
        padval=>undef,
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

    my $padval = 0;
    foreach my $ch (reverse split //, $padmap) {
        $padval <<= 1;
        if ($ch ne '/') {
            $padval += 1;
        }
    }

    $padmap =~ s/..../$& /g;
    $elem->{padmap} = $padmap;
    $elem->{padval} = $padval;

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

sub and_all {
    my ($elems) = @_;
    my $retval;
    foreach my $elem (@$elems) {
        if (defined $retval) {
            $retval &= $elem->{padval};
        } else {
            $retval = $elem->{padval};
        }
    }
    return $retval;
}

sub max_len {
    my ($elems) = @_;
    my $retval = 0;
    foreach my $elem (@$elems) {
        if ($elem->{len} > $retval) {
            $retval = $elem->{len};
        }
    }
    return $retval;
}

&solve_all(\*STDIN);
