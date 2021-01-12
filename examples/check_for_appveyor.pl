#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib examples);

use Ghojo;
use Mojo::Util qw(dumper);

BEGIN { require 'common_things.pl' }

my $ghojo = go_go_ghojo();

my %needs_appveyor;

my $callback = sub( $item, $tx ) {
	my $repo = $item->{name};
	my $owner = $item->{owner}{login};

	my $makefilepl_result = $ghojo->get_contents( $owner, $repo, 'Makefile.PL' );
	unless( $makefilepl_result->is_success ) {
		return 0; # must return defined value
		}

	say "$repo has Makefile.PL";

	if( $item->{'fork'} ) {
		say "\t$repo is a fork";
		return 0;
		}

	my $appveyor_result = $ghojo->get_contents( $owner, $repo, '.appveyor.yml' );
	unless( $appveyor_result->is_success ) {
		say "\tNo appveyor in $repo";
		$needs_appveyor{$repo} = 1;
		}

	if( $appveyor_result->is_error ) {
		return 0;
		}

	return 1;
	};

my $result = $ghojo->get_repos_for_username( $ARGV[0], $callback );
unless( $result->is_success ) {
	say "ERROR: " . $result->message;
	say "Error from " . $result->subroutine;
	}

say dumper( \%needs_appveyor );
