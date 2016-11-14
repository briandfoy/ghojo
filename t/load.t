#!perl

use Test::More 1;

$ENV{GHOJO_LOG_LEVEL} //= 'OFF';

my @classes = qw(
	Ghojo
	Ghojo::Data
	Ghojo::Endpoints
	Ghojo::Mixins::SuccessError
	Ghojo::Result
	);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAIL_OUT( "Could not compile $class" );
	}

done_testing();
