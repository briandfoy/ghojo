#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;

# BurnItToTheGround is my throw-away account for GitHub API testing
my $hash = {
	username => $ARGV[0] // 'BurnItToTheGround',
	password => $ENV{PASSWORD} // prompt_for_password(),
	};

my $label_name = 'Hacktoberfest';

my $ghojo = Ghojo->new( $hash );
$ghojo->logger->level( $ENV{GHOJO_LOG_LEVEL} // 'OFF' );

my $callback = sub ( $item ) {
	unless( ref $item eq ref {} ) {
		$ghojo->logger->error( "Not a hashref!" );
		return;
		}
	my( $user, $repo ) = split m{/}, $item->{full_name};
	my $owner = $item->{owner}{login};
	return unless $ghojo->logged_in_user eq $owner;
	say "Repo is $item->{full_name}";

	my $repo = get_repo_object( $owner, $repo );

	# get the labels for that repo
	my %labels = map { $_->@{ qw(name color) } } $repo->labels->@*;

	unless( exists $labels{$label_name} ) {
		my $rc = $repo->create_label( $label_name, 'ff5500' );
		say "\tCreated $label_name label" if $rc;
		}

	my $callback = sub ( $item ) {
		my( $number, $title ) = $item->@{ qw(number title) };
		say "\t$number: $title";
		$repo->add_labels_to_issue( $number, $label_name );
		return $item;
		};

	return 1;
	};
	my $issues = $repo->issues( $callback );

$ghojo->repos( $callback, {} );

sub prompt_for_password {
	state $rc = require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	print "Type in your secret password: ";
	my $password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	chomp $password;
	$password;
	}
