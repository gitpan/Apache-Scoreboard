use ExtUtils::MakeMaker;

use strict;
use Apache::src ();

my $src = Apache::src->new;

WriteMakefile(
    'NAME'	=> 'Apache::Scoreboard',
    'VERSION_FROM' => 'Scoreboard.pm', 
    'INC'       => $src->inc,	      
    'DEFINE' => $src->define,
    'dist'    => {
        #PREOP => 'pod2text Scoreboard.pm > README',
    },
);
