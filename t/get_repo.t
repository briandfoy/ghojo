use Test::More 0.95;

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
		$ghojo->logger->level( 'OFF' );
		my $response = eval { $repo->labels };
		ok( ref $response );
		isa_ok( $response, ref [] );
		};
	};

subtest bad_repo => sub {
	my $ghojo = $class->new;
	isa_ok $ghojo, $class;
	$ghojo->logger->level( 'OFF' );
	my $rc = $ghojo->$method( $user, $bad_repo );
	ok( ! defined $rc, "bad repo returns undef" );
	};

done_testing();
