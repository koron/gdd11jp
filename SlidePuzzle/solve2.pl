use utf8;
use strict;
use warnings;

sub print_board {
    my ($w, $h, $board, $name) = @_;
    my $idx = 0;
    printf "%s:\n", $name if defined $name;
    for (my $i = 0; $i < $h; ++$i) {
        printf "    %s\n", (substr $board, $idx, $w);
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

sub new_board
{
    my ($w, $h, $s) = @_;
    (my $wallnum = $s) =~ s/[^=]//g;
    return {
        w=>$w,
        h=>$h,
        s=>$s,
        rank=>($w * $h),
        wallnum=>length($wallnum),
    };
}

sub print_board2 {
    my ($board, $name) = @_;
    &print_board($board->{w}, $board->{h}, $board->{s}, $name);
}

my @boards;
<>; <>;
while (<>) {
    chomp;
    my ($w, $h, $s) = split ",";
    push @boards, &new_board($w, $h, $s);
}

@boards = sort { $b->{rank} <=> $a->{rank}
    or $b->{wallnum} <=> $a->{wallnum} } @boards;
foreach (@boards) {
    printf "%d,%s\n", $_->{rank}, $_->{s};
    &print_board2($_);
    my $final = &get_final_status($_->{s});
    &print_board($_->{w}, $_->{h}, $final, '  FINAL');
}
