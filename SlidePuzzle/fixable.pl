#!/usr/bin/perl

use utf8;
use strict;
use warnings;

my $B = join('', qw(
========
=123456=
=789ABC=
=DEFGHI=
=JKLMNO=
=PQRSTU=
=VWXYZ0=
========
));

my $R = &get_fixable_table($B);
# Show fixable table.
for (my $i = 0; $i < 8; ++$i) {
    my $s = substr $R, $i * 8, 8;
    print $s, "\n";
}

sub get_fixable_table {
    my ($start) = @_;
    my $retval = $start;

    # Check each cells are fixable or not.
    for (my $row = 0; $row < 6; ++$row) {
        for (my $col = 0; $col < 6; ++$col) {
            my $pos = $row * 8 + $col + 9;
            if (substr($start, $pos, 1) ne '=') {
                my $fixable = &is_fixable($pos);
                substr $retval, $pos, 1, ($fixable ? "1" : "0");
            }
        }
    }

    return $retval;
}

sub is_fixable {
    my ($pos) = @_;

    if (not &is_cuttable($pos - 8, $pos)
            or not &is_cuttable($pos - 1, $pos)
            or not &is_cuttable($pos + 1, $pos)
            or not &is_cuttable($pos + 8, $pos))
    {
        return 0;
    }

    my @targets = grep {
        not &is_wall($_);
    } ($pos - 8, $pos - 1, $pos + 1, $pos + 8);
    if (scalar(@targets) >= 2) {
        my $pivot = shift @targets;
        return &is_reachable($pivot, \@targets, [$pos]);
    }

    return 1;
}

sub is_reachable {
    my ($start, $targets, $fobidden) = @_;
    my %seen = map { $_ => 1 } @$fobidden;
    my %wants = map { $_ => 1 } @$targets;

    my @queue = ($start);
    while (scalar(@queue) > 0) {
        my $curr = shift @queue;
        my @search = ($curr - 8, $curr - 1, $curr + 1, $curr + 8);
        foreach my $d (@search) {
            next if exists $seen{$d} or &is_wall($d);
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

sub is_cuttable {
    my ($pos, $pivot) = @_;
    return 1 if &is_wall($pos);
    my $count = 0;
    ++$count unless &is_wall2($pos - 8, $pivot);
    ++$count unless &is_wall2($pos - 1, $pivot);
    ++$count unless &is_wall2($pos + 1, $pivot);
    ++$count unless &is_wall2($pos + 8, $pivot);
    return $count >= 2 ? 1 : 0;
}

sub is_wall2 {
    my ($pos, $pivot) = @_;
    return ($pos == $pivot or &is_wall($pos)) ? 1 : 0;
}

sub is_wall {
    return substr($B, $_[0], 1) eq '=';
}
