#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;

use LoopState;

my $base = LoopState->_new('12345670', '8');

my @cases = (
    [ 'case#001', '12345670', '8', 0, '1234567' ],
    [ 'case#002', '12345678', '0', 0, '1234567' ],
    [ 'case#003', '12345680', '7', 0, '1234567' ],

    [ 'case#004a', '07654321', '8', 0, '1234567' ],
    [ 'case#004b', '07654231', '8', 0, '1234567' ],
    [ 'case#004c', '07652341', '8', 0, '1234567' ],
    [ 'case#004d', '07623451', '8', 0, '1234567' ],
    [ 'case#004e', '07234561', '8', 0, '1234567' ],
    [ 'case#004f', '02345671', '8', 0, '1234567' ],

    [ 'case#005', '13245670', '8', 0, '1234567' ],
);

foreach my $case (@cases) {
    my $loop = LoopState->_new($case->[1], $case->[2]);
    my ($power, $target) = $base->power($loop);
    printf("%s: %d, %s\n", $case->[0], $power, $target);
}
