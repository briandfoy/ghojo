#!perl

use Test::More 1;

$ENV{GHOJO_LOG_LEVEL} //= 'OFF';

my @classes = qw(
	Ghojo
	Ghojo::Data
	Ghojo::Endpoints
	Ghojo::Endpoint::Authorizations
	Ghojo::Endpoint::Issues
	Ghojo::Endpoint::Labels
	Ghojo::Endpoint::Miscellaneous
	Ghojo::Endpoint::Repositories
	Ghojo::Endpoint::Users
	Ghojo::Mixins::SuccessError
	Ghojo::Result
	);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAIL_OUT( "Could not compile $class" );
	}

done_testing();
