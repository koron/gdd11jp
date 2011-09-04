package Puzzle;

sub new {
    my ($class, $w, $h, $s) = @_;
    my $raw_final = &_get_final($s);
    return bless {
        -width=>$w,
        -height=>$h,
        -raw_state=>$s,
        -raw_final=>$raw_final,
        -state=>&_get_state($w, $h, $s),
        -final_state=>&_get_state($w, $h, $raw_final),
    }, $class;
}

sub width { return $_[0]->{-width}; }
sub height { return $_[0]->{-height}; }
sub raw_state { return $_[0]->{-raw_state}; }
sub raw_final { return $_[0]->{-raw_final}; }
sub state { return $_[0]->{-state}; }

sub _get_state {
    my ($w, $h, $s) = @_;
    my $r = '=' x 64;
    for (my $row = 0; $row < $h; ++$row) {
        substr($r, $row * 8 + 9, $w, substr($s, $row * $w, $w));
    }
    return $r;
}

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

sub _print_state {
    my ($h, $w, $state, $label, $header) = @_;
    my $H = $h + 2;
    my $W = $w + 2;
    print $label, "\n" if defined $label;
    for (my $row = 0; $row < $H; ++$row) {
        print $header if defined $header;
        my $s = substr($state, $row * 8, $W);
        print $s, "\n";
    }
}

sub print_state {
    my ($this, $label, $header) = @_;
    &_print_state($this->height, $this->width, $this->state, $label, $header);
}

1;
