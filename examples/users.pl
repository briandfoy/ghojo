#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'common_things.pl' }

use Ghojo;
$ENV{GHOJO_LOG_LEVEL} = log_level();
say "log_level is " . log_level();

my $hash = {
	username => username(),
	password => password(),
	};
my $ghojo = Ghojo->new( $hash );

say Dumper( $ghojo->get_logged_in_user );

say '-' x 50;

say Dumper( $ghojo->get_user( 'briandfoy' ) );

say '-' x 50;

$ghojo->set_paged_get_results_limit( 23 );

my $callback = sub ( $item ) {
	my %hash = $item->%{qw(name login email)};
	say Dumper( \%hash );
	$hash;
	};

$ghojo->get_all_users( $callback )
