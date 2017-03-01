#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'common_things.pl' }

use Ghojo;
$ENV{GHOJO_LOG_LEVEL} = log_level();
say "log_level is " . log_level();

my $hash = {
	username     => username(),
	password     => password(),
	authenticate => 0,
	};
my $ghojo = Ghojo->new( $hash );
say "Class returned is " . ref $ghojo;

say "Checking is_error";
if( $ghojo->is_error ) {
	say "Error logging in! " . $ghojo->message;
	my @keys = keys $ghojo->extras->%*;
	say "Exiting!";
	exit;
	}

say "Object is $ghojo";

say '-' x 50;

say "Authenticated user is " . $ghojo->username;

say '-' x 50;

my $callback = sub ( $item, $tx ) {
	state $count =  1;
	state $limit = 23;

	return if $count++ > $limit;
	my %hash = $item->%{qw(name login email)};

	my $result = $ghojo->get_user( $hash{login} );
	my $path = catfile(
		substr( $hash{login}, 0, 1 ),
		substr( $hash{login}, 0, 2 ),
		$hash{login}
		);
	make_path $path unless -d $path;

	if( $result->is_success ) {
		open my $fh, '>:utf8', catfile( $path, 'user.json' );
		print { $fh } $result->extras->{tx}->res->json;
		}

	say "$count: $hash{login}";
	$hash;
	};

say "Calling get_all_users";
my $result = $ghojo->get_all_users( $callback );
if( $result->is_error ) {
	say "Error is getting all users!";
	say $result->message;
	}
else {
	say "Size of list is " . $result->value_count;
	}
