#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;

use Data::Dumper;

my $hash = {
	username => 'briandfoy',
	password => 'tritonX100',
	};

my $ghojo = Ghojo->new( {} );
$ghojo->logger->level( 'TRACE' );

my $callback = sub ( $item ) {
	unless( ref $item eq ref {} ) {
		$ghojo->logger->error( "Not a hashref!" );
		return;
		}
	my( $user, $repo ) = split m{/}, $item->{full_name};
	my $owner = $item->{owner}{login};
	return unless $ghojo->logged_in_user eq $owner;
	say "Repo is $item->{full_name}";

	# get the labels for that repo
	my $labels = $ghojo->labels( $owner, $repo );
	my %labels = map { $_->@{ qw(name color) } } $labels->@*;
	unless( exists $labels{'Hacktoberfest'} ) {
		say "\tHacktoberfest label does not exist";
		$ghojo->create_label( $owner, $repo, 'Hacktoberfest', 'ff5500' );
		}

	if( exists $labels{'bug'} ) {
		say "\tbug label does exist";
		$ghojo->update_label( $owner, $repo, 'Hacktoberfest', 'ff5500' );
		}

	return 1;
	};

my $query = {};

my $repos = $ghojo->repos( $callback, $query );

sub prompt_for_password {
	state $rc = require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	print "Type in your secret password: ";
	my $password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	chomp $password;
	$password;
	}
