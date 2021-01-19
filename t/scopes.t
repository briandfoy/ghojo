use Test::More 1;

my $class = 'Ghojo::Scopes';

subtest setup => sub {
	use_ok( $class );
	};

subtest defined => sub {
	can_ok( $class, 'is_defined' );
	my @defined = qw( repo repo:status workflow );
	my @not_defined = qw( repo.status foo bar );
	ok( $class->is_defined($_), "Scope <$_> is defined" ) for @defined;
	ok( ! $class->is_defined($_), "Scope <$_> is not defined (good)" ) for @not_defined;
	};

subtest blank_object => sub {
	can_ok( $class, 'new' );
	my $obj = $class->new;
	isa_ok( $obj, $class );
	};

subtest add_scopes => sub {
	my $obj = $class->new;
	isa_ok( $obj, $class );
	can_ok( $obj, 'add_scopes' );
	my @added = $obj->add_scopes( @scopes );
	is_deeply( \@scopes, \@added, "all scopes were added" );
	};

subtest add_no_scope => sub {
	my $obj = $class->new( @scopes );
	isa_ok( $obj, $class );
	can_ok( $obj, qw(add_scopes has_scope) );
	is( () = $obj->add_scopes, 0, "Adding no scopes doesn't blow up" );
	};

subtest add_known_scopes => sub {
	my @scopes = qw(repo);
	my $obj = $class->new( @scopes );
	isa_ok( $obj, $class );
	can_ok( $obj, qw(has_scope) );
	ok( $obj->has_scope( $_ ), "has the C<$_> scope" ) for @scopes;
	};

subtest add_unknown_scopes => sub {
	my @scopes = qw(read);
	my $obj = $class->new( @scopes );
	isa_ok( $obj, $class );
	can_ok( $obj, qw(has_scope) );
	ok( ! $obj->has_scope( $_ ), "does not have the invalid C<$_> scope" ) for @scopes;
	};

subtest mixed_scopes => sub {
	my @not_defined = qw(foo bar);
	ok( ! $class->is_defined($_), "Scope <$_> is not defined" ) for @not_defined;
	my @defined = qw(repo);
	ok(   $class->is_defined($_), "Scope <$_> is not defined" ) for @defined;

	my $obj = $class->new( @not_defined, @defined );
	isa_ok( $obj, $class );
	can_ok( $obj, qw(has_scope) );
	ok( ! $obj->has_scope( $_ ), "does not have the invalid C<$_> scope" ) for @not_defined;
	ok(   $obj->has_scope( $_ ), "has the valid C<$_> scope" ) for @defined;
	};

subtest satisfies => sub {
	my $obj = $class->new;
	isa_ok( $obj, $class );
	can_ok( $obj, qw(add_scopes satisfies) );

	$obj->add_scopes( 'repo' );
	ok( $obj->has_scope( 'repo' ), "has the valid C<repo> scope" );
	ok(   $obj->satisfies( 'repo:status' ), "satisfies the repo:status" );
	ok( ! $obj->satisfies( 'workflow' ), "does not satisfy the workflow" );
	};

done_testing();
