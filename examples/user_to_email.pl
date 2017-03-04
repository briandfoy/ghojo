#!/Users/brian/bin/perls/perl5.24.0
use v5.24;

use lib qw(lib);

use Data::Dumper;
use Ghojo;

my $user = shift;

my $result = Ghojo->new->get_user( $user );

if( $result->is_success ) {
	say $result->single_value->{email}
		// '(No email found, or it is private)';
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
