package Apache::Scoreboard;

use strict;

{
    no strict;
    $VERSION = '0.02';
    @ISA = qw(DynaLoader);
    __PACKAGE__->bootstrap($VERSION) if $ENV{MOD_PERL};
}

1;
__END__
