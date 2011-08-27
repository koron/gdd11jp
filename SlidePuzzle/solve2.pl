use utf8;
use strict;
use warnings;

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
}
