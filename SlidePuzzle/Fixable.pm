package Fixable;

use utf8;
use strict;
use warnings;

sub get_fixable_table {
    my ($start) = @_;
    my $retval = $start;

    # Check each cells are fixable or not.
    for (my $row = 0; $row < 6; ++$row) {
        for (my $col = 0; $col < 6; ++$col) {
            my $pos = $row * 8 + $col + 9;
            if (substr($start, $pos, 1) ne '=') {
                my $fixable = &_is_fixable($start, $pos);
                substr $retval, $pos, 1, ($fixable ? "1" : "0");
            }
        }
    }

    return $retval;
}

sub _is_fixable {
    my ($board, $pos) = @_;

    if (not &_is_cuttable($board, $pos - 8, $pos)
            or not &_is_cuttable($board, $pos - 1, $pos)
            or not &_is_cuttable($board, $pos + 1, $pos)
            or not &_is_cuttable($board, $pos + 8, $pos))
    {
        return 0;
    }

    my @targets = grep {
        not &_is_wall($board, $_);
    } ($pos - 8, $pos - 1, $pos + 1, $pos + 8);
    if (scalar(@targets) >= 2) {
        my $pivot = shift @targets;
        return &_is_reachable($board, $pivot, \@targets, [$pos]);
    }

    return 1;
}

sub _is_reachable {
    my ($board, $start, $targets, $fobidden) = @_;
    my %seen = map { $_ => 1 } @$fobidden;
    my %wants = map { $_ => 1 } @$targets;

    my @queue = ($start);
    while (scalar(@queue) > 0) {
        my $curr = shift @queue;
        my @search = ($curr - 8, $curr - 1, $curr + 1, $curr + 8);
        foreach my $d (@search) {
            next if exists $seen{$d} or &_is_wall($board, $d);
            push @queue, $d;
            $seen{$d} = 1;
            if (exists $wants{$d}) {
                delete $wants{$d};
                return 1 if not scalar(%wants);
            }
        }
    }

    return 0;
}

sub _is_cuttable {
    my ($board, $pos, $pivot) = @_;
    return 1 if &_is_wall($board, $pos);
    my $count = 0;
    ++$count unless &_is_wall2($board, $pos - 8, $pivot);
    ++$count unless &_is_wall2($board, $pos - 1, $pivot);
    ++$count unless &_is_wall2($board, $pos + 1, $pivot);
    ++$count unless &_is_wall2($board, $pos + 8, $pivot);
    return $count >= 2 ? 1 : 0;
}

sub _is_wall2 {
    my ($board, $pos, $pivot) = @_;
    return ($pos == $pivot or &_is_wall($board, $pos)) ? 1 : 0;
}

sub _is_wall {
    return substr($_[0], $_[1], 1) eq '=';
}

1;
