#!perl

use Test::More 0.95;

my @classes = qw(
	Ghojo
	);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAIL_OUT( "Could not compile $class" );
	}

done_testing();
