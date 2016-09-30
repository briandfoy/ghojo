#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;

use Data::Dumper;

my $hash = {
	username => 'briandfoy',
	password => 'tritonX100',
	};

my $ghojo = Ghojo->new( {} );
$ghojo->logger->level( 'TRACE' );

my $file = 'github_repo_list.txt';

my $since = 0;
open my $fh, '<:utf8', $file or die "Could not open $file: $!";
while( <$fh> ) {
	s/\A\s*//;
	my( $count, $id, $repo ) = split;
	$since = $id if $id > $since;
	}

$ghojo->logger->trace( "Max id is $since" );

my $callback = sub ( $hashref ) {
	state $count = 0;
	state $fh = do {
		open my $fh, '>>:utf8', $file;
		$fh->autoflush(1);
		$fh;
		};

	printf { $fh } "%4d %6d %s\n",
		$count++,
		$hashref->{id},
		$hashref->{full_name};
	};

$ghojo->set_paged_get_sleep_time(13);
$ghojo->set_paged_get_results_limit( 10_000_000 );

my $json = $ghojo->all_public_repos( $callback, { since => $since } );
