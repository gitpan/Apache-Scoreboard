package Apache::Scoreboard;

use strict;

{
    no strict;
    $VERSION = '0.04';
    @ISA = qw(DynaLoader);
    if ($ENV{MOD_PERL}) {
	__PACKAGE__->bootstrap($VERSION);
    }
    else {
	require Apache::DummyScoreboard;
    }
}

sub fetch {
    my($self, $url) = @_;
    require LWP::Simple;
    my $packet = LWP::Simple::get($url);
    $self->receive($packet);
}

1;
__END__
