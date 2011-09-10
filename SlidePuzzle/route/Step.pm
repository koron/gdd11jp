package Step;

use utf8;
use strict;
use warnings;
use Data::Dumper;
use SeenTable;

my @MOVES = qw/U L R D/;
my @MOVES2 = (
    [qw/U L R D/], [qw/U L D R/], [qw/U R L D/],
    [qw/U R D L/], [qw/U D L R/], [qw/U D R L/],

    [qw/L U R D/], [qw/L U D R/], [qw/L R U D/],
    [qw/L R D U/], [qw/L D U R/], [qw/L D R U/],

    [qw/R U L D/], [qw/R U D L/], [qw/R L U D/],
    [qw/R L D U/], [qw/R D U L/], [qw/R D L U/],

    [qw/D U L R/], [qw/D U R L/], [qw/D L U R/],
    [qw/D L R U/], [qw/D R U L/], [qw/D R L U/],
);

sub set_moves {
    my ($s) = @_;
    @MOVES = split //, $s;
}

sub set_move_type {
    my ($n) = @_;
    @MOVES = @{$MOVES2[$n]};
}

sub new {
    my ($class, $moved, $puzzle, $state, $min_power, $seen) = @_;
    $seen = SeenTable->new() unless $seen;
    my $self = bless {
        -moved => $moved,
        -puzzle => $puzzle,
        -state => $state,
        -pos => index($state, '0'),
        -min_power => $min_power,
        -seen => $seen,
    }, $class;
    $self->{-movable} = $self->_get_movable;
    return $self;
}

sub moved { return $_[0]->{-moved}; }
sub width { return $_[0]->{-puzzle}->width };
sub height { return $_[0]->{-puzzle}->height };
sub state {
    return defined $_[1] ? substr($_[0]->{-state}, $_[1], 1) : $_[0]->{-state};
}
sub pos { return $_[0]->{-pos}; }
sub min_power {
    return defined $_[1] ? $_[0]->{-min_power} = $_[1] : $_[0]->{-min_power};
}
sub seen { return defined $_[1] ? $_[0]->{-seen} = $_[1] : $_[0]->{-seen}; }

sub _wall_check {
    return ($_[0] and $_[0] ne '=') ? $_[0] : undef;
}

sub up {
    my ($self) = @_;
    my $newpos = $self->pos - $self->width;
    return undef if $newpos < 0;
    return &_wall_check($self->state($newpos));
}

sub down {
    my ($self) = @_;
    my $newpos = $self->pos + $self->width;
    return undef if $newpos >= $self->width * $self->height;
    return &_wall_check($self->state($newpos));
}

sub left {
    my ($self) = @_;
    return undef if ($self->pos % $self->width) == 0;
    my $newpos = $self->pos - 1;
    return &_wall_check($self->state($newpos));
}

sub right {
    my ($self) = @_;
    my $newpos = $self->pos + 1;
    return undef if ($newpos % $self->width) == 0;
    return &_wall_check($self->state($newpos));
}

sub next {
    my ($self) = @_;
    my $move = shift @{$self->{-movable}};
    return undef unless defined $move;

    my $puzzle = $self->{-puzzle};
    my $oldpos = $self->pos;
    my $newpos = $oldpos + $puzzle->delta($move);
    my $state = $self->state;
    substr($state, $oldpos, 1 , substr($state, $newpos, 1, '0'));
    my $min_power = $self->min_power;
    my $seen = $self->seen;

    return Step->new($move, $puzzle, $state, $min_power, $seen);
}

sub _get_movable {
    my ($self) = @_;
    my $retval = [];
    my $moved = $self->moved;
    foreach my $d (@MOVES) {
        if ($d eq 'U' and $moved ne 'D' and $self->up) {
            push @$retval, 'U';
        } elsif ($d eq 'L' and $moved ne 'R' and $self->left) {
            push @$retval, 'L';
        } elsif ($d eq 'R' and $moved ne 'L' and $self->right) {
            push @$retval, 'R';
        } elsif ($d eq 'D' and $moved ne 'U' and $self->down) {
            push @$retval, 'D';
        }
    }
    return $retval;
}

1;
