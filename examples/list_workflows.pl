#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;
use Mojo::Util qw(dumper);

my( $user, $field ) = @ARGV;
$field //= 'full_name';

my $result = Ghojo->new->list_workflows( $owner, $repo );

if( $result->is_success ) {
	say "Found " . $result->value_count . " repos";
	say dumper( $result );
	exit;
	}
else {
	say "There was an error";
	say $result->message;

	if( $result->extras->{tx}->res->code == 404 ) {
		say "User <$user> not found";
		exit 1;
		}
	else {
		say 'Unspecified error';
		exit 9;
		}
	}
