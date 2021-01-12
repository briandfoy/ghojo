#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib examples);

use Ghojo;
use Mojo::Util qw(dumper);

BEGIN { require 'common_things.pl' }

my $ghojo = go_go_ghojo();
unless( defined $ghojo ) {
	die "Could not log into GitHub\n";
	}

my $callback = sub( $item, $tx ) {
	state $file = 'Makefile.PL';
	return 0 if $item->{'fork'};

	my $repo  = $item->{name};
	my $owner = $item->{owner}{login};

	my $makefilepl_result = $ghojo->get_decoded_contents( $owner, $repo, $file );
	unless( $makefilepl_result->is_success ) {
		return 0; # must return defined value
		}

	my $content = $makefilepl_result->single_value;

	my( $license ) = $content =~ m/ 'LICENSE' \s+ => \s+ '(.*?)' /x;
	unless( defined $license ) {
		Ghojo->logger->warn( "No license in $file for $repo" );
		return 0;
		}
	return 1 if $license eq 'artistic2';

	say "$item->{name}: License is $license";
	return 1;
	};

unless( defined $ARGV[0] ) {
	die "The first and only argument is the GitHub username\n"
	};

my $result = $ghojo->get_repos_for_username( $ARGV[0], $callback );
unless( $result->is_success ) {
	say "ERROR: " . $result->message;
	say "Error from " . $result->subroutine;
	}
