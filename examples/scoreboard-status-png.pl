use strict;
use Apache::Scoreboard ();
use PNGgraph::pie ();

use constant IS_MODPERL => exists $ENV{MOD_PERL};

my($image, $r);
if (IS_MODPERL) {
    $r = shift;
    $r->send_http_header('image/gif');
    $image = Apache::Scoreboard->image;
}
else {
    my $host = shift || "localhost";
    $image = Apache::Scoreboard->fetch("http://$host/scoreboard");
}

my %data = ();
my %status = 
  (
   '.' => "Open Slot",
   'S' => "Starting",
   '_' => "Waiting",
   'R' => "Reading",
   'W' => "Writing",
   'K' => "Keepalive",
   'L' => "Logging",
   'D' => "DNS Lookup",
   'G' => "Finishing",
  );

my @labels = values %status;

for (my $parent = $image->parent; $parent; $parent = $parent->next) {
    my $server = $parent->server;
    $data{ $status{ $server->status } }++;
}

my @nlabels = map { "$_ ($data{$_})" } keys %data;

my $data = [\@nlabels, [@data{keys %data}]];

my $graph = PNGgraph::pie->new(250, 200);

$graph->set( 
   title => 'Server Status',
   pie_height => 36,
   axislabelclr => 'black',
);

if (IS_MODPERL) {
    print $graph->plot($data);
}
else {
    $graph->plot_to_png("scoreboard-status.png", $data);
}
