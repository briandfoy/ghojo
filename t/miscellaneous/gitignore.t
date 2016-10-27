use v5.24;

use Test::More 1;

use Mojo::Util qw( dumper );

my $class  = 'Ghojo';
my $method = 'get_gitignore_template_names';

use_ok( $class );

my $ghojo = Ghojo->new;
isa_ok( $ghojo, $class );
isa_ok( $ghojo, 'Ghojo::PublicUser' );
can_ok( $ghojo, $method );

my $result = $ghojo->$method();
isa_ok( $result, 'Ghojo::Result' ) or diag( dumper( $result ) );
isa_ok( $result->values->first, 'Ghojo::Data::Gitignore' );

can_ok( $ghojo, 'gitignore_template_cache' );
isa_ok( $ghojo->gitignore_template_cache, ref {} );
ok( $ghojo->gitignore_template_cache->%*, "There are some hash keys in the cache" );

subtest name_exists => sub {
	my $name = 'Perl';

	ok( $ghojo->gitignore_template_name_exists( $name ),
		"There's a gitignore template for <$name>" );
	my $result = $ghojo->get_gitignore_template( $name );
	isa_ok( $result, 'Ghojo::Result' );
	ok( $result->is_success, "Result for no cache hit is a success" );
	ok( exists $result->extras->{cache_hit}, "The cache hit key is there before caching" );
	ok( ! $result->extras->{cache_hit}, "This was not a cache hit" );

	my $cache_result = $ghojo->get_gitignore_template( $name );
	isa_ok( $cache_result, 'Ghojo::Result' );
	isa_ok( $cache_result->extras, 'HASH' );
	ok( $result->is_success, "Result for expected cache hit is a success" );
	ok( exists $cache_result->extras->{cache_hit}, "The cache hit key is there after caching" );
	ok( $cache_result->extras->{cache_hit}, "This was a cache hit" );

	};

subtest BenderBiteMe => sub {
	my $name = 'bite_my_shiny_ass';

	ok( ! $ghojo->gitignore_template_name_exists( $name ),
		"There's not a gitignore template for <$name>" );
	my $result = $ghojo->get_gitignore_template( $name );
	isa_ok( $result, 'Ghojo::Result' );
	ok( $result->is_error, "This is an error result" );
	};

done_testing();
