package Apache::Scoreboard;

use strict;
use constant DEBUG => 0;

BEGIN {
    no strict;
    $VERSION = '0.05';
    @ISA = qw(DynaLoader);
    if ($ENV{MOD_PERL}) {
	__PACKAGE__->bootstrap($VERSION);
    }
    else {
	require Apache::DummyScoreboard;
    }
}

my $ua;

sub fetch {
    my($self, $url) = @_;

    require LWP::UserAgent;
    unless ($ua) {
	no strict 'vars';
	$ua = LWP::UserAgent->new;
	$ua->agent(join '/', __PACKAGE__, $VERSION);
    }

    my $request = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request);
    unless ($response->is_success) {
	warn "request failed: ", $response->status_line if DEBUG;
	return undef;
    }

    my $type = $response->header('Content-type');
    unless ($type eq Apache::Scoreboard::REMOTE_SCOREBOARD_TYPE) {
	warn "invalid scoreboard Content-type: $type" if DEBUG;
	return undef;
    }

    my $packet = $response->content;
    return undef unless $packet;
    $self->thaw($packet);
}

1;
__END__

