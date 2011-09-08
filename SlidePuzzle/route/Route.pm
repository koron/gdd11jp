package Route;

use utf8;
use strict;
use warnings;

sub new {
    my ($class, $array, $spots) = @_;
    return bless {
        -array => $array,
        -spots => $spots,
    }, $class;
}

sub array { return $_[0]->{-array} }
sub spots { return $_[0]->{-spots} }

1;
