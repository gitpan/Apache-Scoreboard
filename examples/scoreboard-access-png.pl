use strict;
use Apache::Scoreboard ();
use PNGgraph::bars ();

use constant IS_MODPERL => exists $ENV{MOD_PERL};
use constant KB => 1024;

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

my(@labels, @access, @bytes);
my($total_access, $total_bytes);

for (my $parent = $image->parent; $parent; $parent = $parent->next) {
    push @labels, $parent->pid;
    my $server = $parent->server;

    my $count = $server->access_count;
    push @access, $count;
    $total_access += $count;

    my $bytes = $server->bytes_served;
    push @bytes, $bytes / KB;
    $total_bytes += $bytes;
}

my $data = [\@labels, \@access, \@bytes];

my $graph = PNGgraph::bars->new;

$graph->set( 
   x_label => 'Child PID',
   y1_label => 'Access Count',
   y2_label => 'Bytes Served (KB)',
   title => 'Server Access',
   long_ticks => 1,
   bar_spacing => 2,
   two_axes => 1,
   x_labels_vertical => 1,
   x_label_position => 1/2,
   dclrs => [qw(lred lblue)],
);

my $bytes_str = Apache::Scoreboard::size_string($total_bytes);

$graph->set_legend("Access Count ($total_access total)", 
		   "Bytes Served (KB) ($bytes_str total)");

if (IS_MODPERL) {
    print $graph->plot($data);
}
else {
    $graph->plot_to_png("scoreboard-access.png", $data);
}


