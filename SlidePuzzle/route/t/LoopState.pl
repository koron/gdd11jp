#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;

use LoopState;

my $base = LoopState->_new('12345670', '8');

my @cases = (
    [ 'case#001a', '12345670', '8' ],
    [ 'case#001b', '12345678', '0' ],
    [ 'case#001c', '12345680', '7' ],

    [ 'case#002a', '07654321', '8' ],
    [ 'case#002b', '07654231', '8' ],
    [ 'case#002c', '07652341', '8' ],
    [ 'case#002d', '07623451', '8' ],
    [ 'case#002e', '07234561', '8' ],
    [ 'case#002f', '02345671', '8' ],

    [ 'case#003', '13245670', '8' ],
);

foreach my $case (@cases) {
    my $loop = LoopState->_new($case->[1], $case->[2]);
    my ($power, $target) = $base->power($loop);
    printf("%s: %d, %s\n", $case->[0], $power, $target);
}
