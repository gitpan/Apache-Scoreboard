use strict;
use Apache::Scoreboard ();
use PNGgraph::bars ();

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

my(@labels, @cpu, @req_time);
my($total_cpu, $total_req_time);

for (my $parent = $image->parent; $parent; $parent = $parent->next) {
    push @labels, $parent->pid;
    my $server = $parent->server;

    my $cpu = $server->times;
    push @cpu, $cpu;
    $total_cpu += $cpu;

    my $req_time = $server->req_time;
    push @req_time, $req_time;
    $total_req_time += $req_time;
}

my $data = [\@labels, \@cpu, \@req_time];

my $graph = PNGgraph::bars->new;

$graph->set( 
   x_label => 'Child PID',
   y1_label => 'CPU',
   y2_label => 'Request Time',
   title => 'Server CPU Usage',
   long_ticks => 1,
   bar_spacing => 2,
   two_axes => 1,
   x_labels_vertical => 1,
   x_label_position => 1/2,
   dclrs => [qw(lred lblue)],
);

$graph->set_legend("CPU ($total_cpu total)", 
		   "Request Time (in milliseconds) ($total_req_time total)");

if (IS_MODPERL) {
    print $graph->plot($data);
}
else {
    $graph->plot_to_png("scoreboard-cpu.png", $data);
}


