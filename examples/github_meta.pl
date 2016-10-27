#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Mojo::Util qw(dumper);

use Ghojo;

my $ghojo = Ghojo->new;

my $result = $ghojo->get_github_info;
if( $result->is_success ) {
	say "Meta is " . dumper( $result->values->first );
	}
