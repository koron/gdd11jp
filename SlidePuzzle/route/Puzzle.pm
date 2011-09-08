package Puzzle;

use utf8;
use strict;
use warnings;

sub new {
    my ($class, $w, $h, $state) = @_;
    my $final = &_get_final($state);
    $w += 0;
    $h += 0;
    return bless {
        -width=>$w,
        -height=>$h,
        -state=>$state,
        -final=>$final,
        -delta => {
            'L' => -1,
            'R' => 1,
            'U' => -$w,
            'D' => $w,
        },
    }, $class;
}

sub w { return $_[0]->{-width}; }
sub h { return $_[0]->{-height}; }
sub width { return $_[0]->{-width}; }
sub height { return $_[0]->{-height}; }
sub state { return $_[0]->{-state}; }
sub final { return $_[0]->{-final}; }
sub delta { return $_[0]->{-delta}->{$_[1]}; }

sub _get_final {
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

sub move {
    my ($self, $pos, $ch) = @_;
    my ($w, $h) = ($self->width, $self->height);
    if ($ch eq 'L') {
        return $pos - 1 if ($pos % $w) > 0;
    } elsif ($ch eq 'R') {
        return $pos + 1 if ($pos % $w) < $w - 1;
    } elsif ($ch eq 'U') {
        return $pos - $w if $pos >= $w;
    } elsif ($ch eq 'D') {
        return $pos + $w if $pos + $w < $w * $h;
    }
    return -1;
}

sub print_state {
    my ($self, $label, $header) = @_;
    print $label, "\n" if defined $label;
    my $H = $self->height;
    my $W = $self->width;
    my $S = $self->state;
    for (my $row = 0; $row < $H; ++$row) {
        print $header if defined $header;
        print substr($S, $row * $W, $W), "\n";
    }
}

1;
