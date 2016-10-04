use v5.24;

use Data::Dumper;

# BurnItToTheGround is my throw-away account for GitHub API testing
sub default_username  { 'BurnItToTheGround' }
sub username { $ARGV[0] // default_username() }

sub default_log_level { 'OFF' }
sub log_level { $ENV{GHOJO_LOG_LEVEL} // default_log_level() }

sub password { $ENV{PASSWORD} // prompt_for_password() }

sub prompt_for_password {
	state $rc = require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	print "Type in your secret password: ";
	my $password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	print $1 if $password =~ s/(\s+)\z//;
	$password;
	}

1;
