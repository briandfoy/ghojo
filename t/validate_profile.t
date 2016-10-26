use v5.24;

use Test::More 1;

my $class  = 'Ghojo';
my $method = 'validate_profile';

use_ok( $class );
can_ok( $class, $method );

subtest empty_profile_and_args => sub {
	# fails because $profile is missing the params keys
	my $profile = {};
	my $args    = {};

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_error' );
	ok( $result->is_error, "Empty profile fails" )
		or diag( $result->message );
	};

subtest empty_params_and_args => sub {
	# succeeds because $profile has missing the params keys
	my $profile = { params => {} };
	my $args    = {};

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_success' );
	ok( $result->is_success, "Empty params passes" )
		or diag( $result->message );
	};

subtest none_required_none_passed => sub {
	# succeeds because there is nothing in args to fail
	my $profile = {
		params => { animal => qr/octocat/ }
		};
	my $args    = {};

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_success' );
	ok( $result->is_success, "None required passes" )
		or diag( $result->message );
	};

subtest one_required_none_passed => sub {
	# fails because there is nothing in args to match
	my $profile = {
		params => { animal => qr/octocat/ },
		required => [ qw(animal) ],
		};
	my $args    = {};

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_error' );
	like( $result->message, qr/^Missing/m, 'Extra arguments' );
	ok( $result->is_error, "One required (and missing) fails" );
	};

subtest one_required_good_one_passed => sub {
	my $profile = {
		params => { animal => qr/octocat/ },
		required => [ qw(animal) ],
		};
	my $args    = { animal => 'I am an octocatergory' };

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_success' );
	ok( $result->is_success, "One required (and supplied) succeeds" )
		or diag( $result->message );
	};

subtest one_required_bad_one_passed => sub {
	my $profile = {
		params => { animal => qr/octocat/ },
		required => [ qw(animal) ],
		};
	my $args    = { animal => 'I am an octopus' };

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_error' );
	ok( $result->is_error, "One required (and bad one supplied) fails" );
	};

subtest one_required_extra_one_passed => sub {
	my $profile = {
		params => { animal => qr/octo/ },
		required => [ qw(animal) ],
		};
	my $args    = {
		animal => 'I am an octopus',
		robot  => 'Bender',
		};

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_error' );
	like( $result->message, qr/^Extra/m, 'Extra arguments' );
	ok( $result->is_error, "One extra fails" );
	};

subtest the_big_one_succeeds => sub {
	my $profile = {
		params => {
			animal => qr/octo/,
			robot  => "Bender",
			human  => [ qw(Fry Farnsworth) ],
			pilot  => sub { lc $_[0] eq lc 'Leela' },
			},
		required => [ qw(animal) ],
		};
	my $args    = {
		animal => 'I am an octopus',
		robot  => 'Bender',
		human  => 'Fry',
		pilot  => 'LeEla'
		};

	my $result = $class->$method( $args, $profile );
	isa_ok( $result, 'Ghojo::Result' );
	can_ok( $result, 'is_success' );
	ok( $result->is_success, "Big one passes" );
	};

done_testing();
