#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Ghojo;
use Mojo::Util qw(dumper);

my( $repo ) = @ARGV;

my $ghojo = Ghojo->new({
	token => $ENV{GITHUB_TOKEN},
	});

my $result = $ghojo->create_repo( $repo );
say dumper( $result );

my $owner;
if( $result->is_success ) {
	say "Repo created!";
	my $owner = $result->values->[0]->owner->login;
	say "Owner is $owner";
	my $result = $ghojo->get_repo( $owner, $repo );
	}
else {
	say "Creating repo failed. Message: " . $result->message;
	exit;
	}

say "Press enter to delete repo";
<STDIN>;

my $result = $ghojo->delete_repo( $owner, $repo );
if( $result->is_success ) {
	say "Repo created!";
	}
else {
	say "Deleting repo failed. Message: " . $result->message;
	exit;
	}
