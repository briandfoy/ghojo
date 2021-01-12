#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);

use Mojo::Util qw(dumper);

use Ghojo;

my $ghojo = Ghojo->new;

my $result = $ghojo->get_github_info;
if( $result->is_success ) {
	say "Meta is " . dumper( $result->values->first );
	}
