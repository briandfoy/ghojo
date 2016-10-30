#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'common_things.pl' }

my( $action, $number ) = @ARGV;
my $method = do {
	   if( $ARGV[0] eq 'lock'   ) { 'lock_an_issue'   }
	elsif( $ARGV[0] eq 'unlock' ) { 'unlock_an_issue' }
	else { die "Action should be either lock or unlock\n" }
	};

my $ghojo = get_authenticated_user();
say "locking_an_issue: Class name is " . $ghojo->class_name;
say dumper( $ghojo );

say "Success: ",  $ghojo->is_success;
say "Error:   ",  $ghojo->is_error;

unless( $ghojo->is_success ) {
	say "Could not create object: " . $ghojo->message;
	exit 3;
	}

my $repo_pair = join "/", username(), default_repo();

unless( $ghojo->repo_is_available( username(), default_repo() ) ) {
	say "Repo $repo_pair does not exist!";
	exit 1;
	}

unless( $ghojo->issue_exists( username(), default_repo(), $number ) ) {
	say "Issue #$number does not exist in $repo_pair";
	}

my $lock_result = $ghojo->$method( username(), default_repo(), $number );
unless( $lock_result->is_success ) {
	say "Could not $action issue $number: " . $lock_result->message;
	exit 2;
	}
