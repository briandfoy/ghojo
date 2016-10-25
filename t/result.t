use Test::More;

my $class = 'Ghojo::Result';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'error' );
	};

done_testing();
