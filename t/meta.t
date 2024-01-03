use v5.26;
use strict;

use Test::More;
END{ done_testing() }

BAIL_OUT( "Set GHOJO_TOKEN to use the Meta API" )
	unless defined $ENV{GHOJO_TOKEN};

use Mojo::Util qw(dumper);

my $ghojo;

subtest "load" => sub {
	use_ok( 'Ghojo' ) or BAIL_OUT( "Could not load Ghojo" );
	};

subtest "ghojo login" => sub {
	$ghojo = Ghojo->new( { token => $ENV{GHOJO_TOKEN} } );
	ok( $ghojo->is_success, "Ghojo login successful" )
		or BAIL_OUT( "Could not login to GitHub API\n" . $ghojo->summary );
	};

subtest "octocat" => sub {
	my $octocat = $ghojo->octocat;
	my $string = $octocat->single_value->string;

	like $string, qr/:~==~==~==~==~~/, 'Last night is there';
	};

subtest "zen" => sub {
	my $zen = $ghojo->zen;
	my $string = $zen->single_value->string;

	ok( defined $string, "We got back some string" );
	};
