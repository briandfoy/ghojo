#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Ghojo;
use Mojo::Util qw(dumper);

my( $owner, $repo ) = split m|/|, $ARGV[0];

my $ghojo = Ghojo->new({ token => $ENV{GITHUB_TOKEN} });
if( $ghojo->is_error ) {
	say $ghojo->short_summary;
	exit;
	}

my $result = $ghojo->delete_repo( $owner, $repo );

if( $result->is_success ) {
	say "Repo deleted!";
	}
else {
	say $result->long_summary;
	}
