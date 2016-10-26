#!/Users/brian/bin/perls/perl5.24.0
use v5.24;

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;

my $user = shift;

my $callback = sub ( $repo ) { $repo->full_name };

my $result = Ghojo->new->get_repos_for_username( $user, $callback );

if( $result->is_success ) {
	my $count = 1;
	$result->values->map( sub {
		say "$count: $_";
		$count++;
		});
	exit;
	}
else {
	if( $result->extras->{tx}->res->code == 404 ) {
		say "User <$user> not found";
		exit 1;
		}
	else {
		say 'Unspecified error';
		exit 9;
		}
	}
