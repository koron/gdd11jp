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

my $R = $B;
for (my $row = 0; $row < 6; ++$row) {
    for (my $col = 0; $col < 6; ++$col) {
        my $pos = $row * 8 + $col + 9;
        if (substr($B, $pos, 1) ne '=') {
            my $fixable = &is_fixable($pos);
            substr $R, $pos, 1, ($fixable ? "1" : "0");
        }
    }
}
for (my $i = 0; $i < 8; ++$i) {
    my $s = substr $R, $i * 8, 8;
    print $s, "\n";
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

    # TODO:

    return 1;
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
