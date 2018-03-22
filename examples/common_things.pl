use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Ghojo;
use Data::Dumper;
use Mojo::Util qw(dumper);

# BurnItToTheGround is my throw-away account for GitHub API testing
sub default_username  { 'BurnItToTheGround' }
sub username          { $ENV{GHOJO_USERNAME} // default_username() }
sub default_repo      { 'test_repo' }

sub password          { $ENV{GHOJO_PASSWORD} // prompt_for_password() }

sub default_log_level { 'OFF' }
sub log_level         { uc($ENV{GHOJO_LOG_LEVEL}) // default_log_level() }

sub prompt_for_password {
	state $rc = require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	print "Type in your secret password: ";
	my $password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	print $1 if $password =~ s/(\s+)\z//;
	$ENV{PASSWORD} = $password;
	}

sub get_authenticated_user {
	my $hash = {
		username => username(),
		password => password(),
		};
	say dumper( $hash );

	my $ghojo = Ghojo->new( $hash );
	}

sub go_go_ghojo () {
	state $rc = require Ghojo;
	$ENV{GHOJO_LOG_LEVEL} = log_level();
	say "GHOJO_LOG_LEVEL is " . log_level();

	# we log in because there's a higher API rate limit.
	my $hash = {
		username     => username(),
		password     => password(),
		authenticate => 0,
		};
	my $ghojo = Ghojo->new( $hash );

	$ghojo->logger->trace( "Checking Login" );
	if( $ghojo->is_error ) {
		say "Error logging in! " . $ghojo->message;
		my @keys = keys $ghojo->extras->%*;
		say "Exiting!";
		exit;
		}
	$ghojo->logger->trace( "Login was not an error" );

	$ghojo;
	}

say "Common things loaded!";

1;
