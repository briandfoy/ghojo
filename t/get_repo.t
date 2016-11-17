use Test::More 1;

my $class      = 'Ghojo';
my $repo_class = 'Ghojo::Repo';
my $method     = 'get_repo_object';
my $user       = 'BurnItToTheGround';
my $repo       = 'test_repo';
my $bad_repo   = 'is_not_there';

$ENV{GHOJO_LOG_LEVEL} //= 'OFF';

subtest setup => sub {
	use_ok $class;
	can_ok $class, $method;
	};

subtest good_repo => sub {
	my $ghojo = $class->new;
	isa_ok $ghojo, $class;

	my $repo  = $ghojo->$method( $user, $repo );
	isa_ok( $repo, $repo_class );
	can_ok( $repo, 'data' );
	ok( exists $repo->data->{full_name}, "full_name key exists" );
	diag( "Repo name is " . $repo->data->{full_name} );

	subtest labels => sub {
		my $result = eval { $repo->labels };
		isa_ok( $result, 'Ghojo::Result' );

		my $array = $result->values;
		ok( ref $array, 'Values for label list is a reference' );
		isa_ok( $array, ref [] );
		diag( "Labels is [@$array]" );
		};
	};

subtest bad_repo => sub {
	my $ghojo = $class->new;
	isa_ok $ghojo, $class;
	my $result = $ghojo->$method( $user, $bad_repo );
	diag( "Result is " . ref $result );
	isa_ok( $result, 'Ghojo::Result', "bad repo returns Result object" );
	ok( $result->is_error, '404 response is an error' );
	};

done_testing();
