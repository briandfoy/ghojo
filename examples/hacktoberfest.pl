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

my $callback = sub ( $hashref ) {
	unless( ref $hashref eq ref {} ) {
		$ghojo->logger->error( "Not a hashref!" );
		return;
		}
	my( $user, $repo ) = split m{/}, $hashref->{full_name};
	my $owner = $hashref->{owner}{login};
	return unless $self->username eq $owner;
	[ $user, $repo ]
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
