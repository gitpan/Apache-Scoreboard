use ExtUtils::MakeMaker;

use strict;
use Apache::src ();

my $src = Apache::src->new;
my $typemaps = $src->typemaps;

#mmm
system "cp ../typemap ." unless -e "typemap";
system "cat dummy.c ../Scoreboard.xs > DummyScoreboard.xs";
system $^X, "-pi", "-e",
  "s/(MODULE *= *Apache::)Scoreboard/\$1.DummyScoreboard/e", 
  "DummyScoreboard.xs";

WriteMakefile(
    'NAME'	=> 'Apache::DummyScoreboard',
    'VERSION_FROM' => 'DummyScoreboard.pm', 
    'INC'       => "-I../ " . $src->inc,	      
    'DEFINE' => $src->define,
    'TYPEMAPS' => $typemaps,
);
