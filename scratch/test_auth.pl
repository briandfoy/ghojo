#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;

say '-' x 50;
test( do { local *Ghojo::token_file = sub {}; Ghojo->new( {} ) } );

say '-' x 50;
Ghojo->clear_rate_limit_cache;
test( Ghojo->new( { token => $ENV{GHOJO_DEV_TOKEN} } ) );

sub test ( $ghojo ) {
	say $ghojo->class_name;

	say "Can handle the public api: ",           $ghojo->handles_public_api;
	say "Can handle the authenticated api: ",    0 + $ghojo->handles_authenticated_api;

	say "Core rate limit is: ",                  $ghojo->core_rate_limit;
	say "Is the public api rate limit: ",        $ghojo->is_public_api_rate_limit;
	say "Is the authenticated api rate limit: ", 0 + $ghojo->is_authenticated_api_rate_limit;

	say "time is " . time;
	say "time to reset is " . $ghojo->seconds_until_core_rate_limit_reset;

	say "authentication test is " , 0 + $ghojo->test_authenticated;
	}
