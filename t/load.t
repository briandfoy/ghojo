#!perl

use Test::More 1;

$ENV{GHOJO_LOG_LEVEL} //= 'OFF';

my @classes = qw(
	Ghojo
	Ghojo::Endpoints
	Ghojo::Endpoint::Users
	Ghojo::Endpoint::Authorizations
	Ghojo::Endpoint::Labels
	Ghojo::Endpoint::Issues
	Ghojo::Endpoint::Repositories
	);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAIL_OUT( "Could not compile $class" );
	}

done_testing();
