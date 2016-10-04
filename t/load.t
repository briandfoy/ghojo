#!perl

use Test::More 0.95;

$ENV{GHOJO_LOG_LEVEL} //= 'OFF';

my @classes = qw(
	Ghojo
	);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAIL_OUT( "Could not compile $class" );
	}

done_testing();
