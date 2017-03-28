#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(
	/Users/brian/Dropbox/Dev/Ghojo/lib
	/Users/brian/Dropbox/Dev/Ghojo/examples
	);

use Data::Dumper;
use File::Basename        qw(basename);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile);
use IO::Interactive       qw(interactive);
use JSON::XS              qw(encode_json); # This should be Mojo::JSON

select interactive();

BEGIN { require 'common_things.pl' }

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

my $ghojo = go_go_ghojo();

$ghojo->create_issue_comment(
	'briandfoy',
	'pegs-pdf',
	1,
	{ body => "Test comment" }
	);
