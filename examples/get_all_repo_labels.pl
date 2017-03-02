#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(
	/Users/brian/Dropbox/Dev/Ghojo/lib
	/Users/brian/Dropbox/Dev/Ghojo/examples
	);

use Data::Dumper;
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use JSON::XS qw(encode_json);

BEGIN { require 'common_things.pl' }

use Ghojo;
$ENV{GHOJO_LOG_LEVEL} = log_level();
say "log_level is " . log_level();


=pod

# we log in beacuse there's a higher API rate limit.
my $hash = {
	username     => username(),
	password     => password(),
	authenticate => 0,
	};
my $ghojo = Ghojo->new( $hash );

say "Checking is_error";
if( $ghojo->is_error ) {
	say "Error logging in! " . $ghojo->message;
	my @keys = keys $ghojo->extras->%*;
	say "Exiting!";
	exit;
	}

=cut

my $file = '/Volumes/Big Scratch/github_repos/github_repos.txt';
open my $fh, '<:utf8', $file or die "Could not open file: $!\n";
while( <$fh> ) {
	chomp;
	my( $id, $user_repo ) = split;
	my( $user, $repo ) = split m| / |x, $user_repo;

	last if $count++ > 50;
	}
