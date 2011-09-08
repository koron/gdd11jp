package Step;

use utf8;
use strict;
use warnings;

sub new {
    my ($class, $moved, $puzzle, $state) = @_;
    my $self = bless {
        -moved => $moved,
        -puzzle => $puzzle,
        -state => $state,
        -pos => index($state, '0'),
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
    return Step->new($move, $puzzle, $state);
}

sub _get_movable {
    my ($self) = @_;
    my $retval = [];
    my $moved = $self->moved;
    if ($moved ne 'D' and $self->up) {
        push @$retval, 'U';
    }
    if ($moved ne 'R' and $self->left) {
        push @$retval, 'L';
    }
    if ($moved ne 'L' and $self->right) {
        push @$retval, 'R';
    }
    if ($moved ne 'U' and $self->down) {
        push @$retval, 'D';
    }
    return $retval;
}

1;
