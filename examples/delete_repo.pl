#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Ghojo;
use Mojo::Util qw(dumper);

my( $owner, $repo ) = split m|/|, $ARGV[0];

my $ghojo = Ghojo->new({
	token => $ENV{GITHUB_TOKEN},
	});


my $result = $ghojo->delete_repo( $owner, $repo );
say dumper( $result );
if( $result->is_success ) {
	say "Repo deleted!";
	}
else {
	say "Deleting repo failed. Message: " . $result->message;
	exit;
	}
