use strict;
use Apache::Scoreboard ();
use PNGgraph::lines ();
use GTop ();

use constant IS_MODPERL => exists $ENV{MOD_PERL};
use constant KB => 1024;

my($image, $r, $gtop_host);
if (IS_MODPERL) {
    $r = shift;
    $r->send_http_header('image/gif');
    $image = Apache::Scoreboard->image;
    $gtop_host = $r->dir_config("GTopHost");
}
else {
    my $host = shift || "localhost";
    $image = Apache::Scoreboard->fetch("http://$host/scoreboard");
    $gtop_host = shift;
}

$gtop_host ||= ""; #-w
my $gtop = $gtop_host ? GTop->new($gtop_host) : GTop->new;

my %data = ();
my %total = ();
my @mem = qw(size share vsize rss real);
my $pids = $image->pids;

for my $pid (@$pids) {
    push @{ $data{labels} }, $pid;

    my $mem = $gtop->proc_mem($pid);
    for (@mem) {
	next unless $mem->can($_); #real
	my $val = $mem->$_();
	push @{ $data{$_} }, $val/KB;
	$total{$_} += $val;
    }
    my $real = $data{size}->[-1] - $data{share}->[-1]; 
    push @{ $data{real} }, $real;
    $total{real} += $real * KB;
}

my $data = [@data{'labels', @mem}];

my $graph = PNGgraph::lines->new;

$graph->set( 
   x_label => 'Child PID',
   y_label => 'size',
   title => "$gtop_host Apache Memory Usage",
   y_tick_number => 8,
   y_label_skip => 2,
   line_width => 3,
   y_number_format => sub { 
       sprintf "%s", GTop::size_string(KB * shift);
   },
);

$graph->set_legend(map { 
    my $str = GTop::size_string($total{$_});
    "$_ ($str total)";
} @mem);


if (IS_MODPERL) {
    print $graph->plot($data);
}
else {
    $graph->plot_to_png("scoreboard-mem-usage.png", $data);
}


