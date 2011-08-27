use utf8;
use strict;
use warnings;

use Data::Dumper;

sub print_board {
    my ($w, $h, $board, $name) = @_;
    my $idx = 0;
    printf "%s:\n", $name if defined $name;
    for (my $i = 0; $i < $h; ++$i) {
        printf "  %s\n", (substr $board, $idx, $w);
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

my ($w, $h) = (5, 6);
my $first = '12=E4D9HIF8=GN576LOABMTPKQSR0J';
my $final = &get_final_status($first);
&print_board($w, $h, $first, 'FIRST');
&print_board($w, $h, $final, 'FINAL');
