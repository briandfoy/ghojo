#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);

use Ghojo;

use Mojo::Util qw(dumper);

my $ghojo = Ghojo->new;

my $pair = shift;
my( $owner, $repo ) = split m|/|, $pair;
$ghojo->logger->debug( "Owner is $owner" );
$ghojo->logger->debug( "Repo is $repo" );


my $callback = sub ( $item, $tx ) {
	state $count = 0;
	say sprintf "%3d\t%s", $item->@{qw(number title)}
	};

say "Issues for $pair";
my $result = $ghojo->issues_on_repo( $owner, $repo, $callback );
if( $result->is_error ) {
	say "Error! " . $result->message;
	exit 1;
	}
