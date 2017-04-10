#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;
use Mojo::Util qw(dumper);

my $ghojo = Ghojo->new;

my $callback = sub( $item, $tx ) {
	my $repo = $item->{name};
	my $owner = $item->{owner}{login};

	my $makefilepl_result = $ghojo->get_contents( $owner, $repo, 'Makefile.PL' );
	unless( $makefilepl_result->is_success ) {
		return 0; # must return defined value
		}

	say "$repo has Makefile.PL";
	return 1;
	};

my $result = $ghojo->get_repos_for_username( $ARGV[0], $callback );
unless( $result->is_success ) {
	say "ERROR: " . $result->message;
	say "Error from " . $result->subroutine;
	}
