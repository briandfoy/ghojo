use v5.24;

use Ghojo;
use Mojo::Util qw(dumper);

# BurnItToTheGround is my throw-away account for GitHub API testing
sub default_username  { 'BurnItToTheGround' }
sub username          { $ENV{GHOJO_USERNAME} // default_username() }
sub default_repo      { 'test_repo' }

sub password          { $ENV{PASSWORD} // prompt_for_password() }

sub default_log_level { 'OFF' }
sub log_level         { $ENV{GHOJO_LOG_LEVEL} // default_log_level() }

sub prompt_for_password {
	state $rc = require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	print "Type in your secret password: ";
	my $password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	print $1 if $password =~ s/(\s+)\z//;
	$password;
	}

sub get_authenticated_user {
	my $hash = {
		username => username(),
		password => password(),
		};
	say dumper( $hash );

	my $ghojo = Ghojo->new( $hash );
	}

1;
