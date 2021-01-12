#!perl
use v5.24;
use experimental qw(signatures);

use File::Spec::Functions qw(catfile rel2abs);
use JSON::XS;

my $file = $ARGV[0] or @ARGV = (
	'/Volumes/Big Scratch/github_repos/github_repos.txt',
	'/Volumes/Micron 1Tb/github_repos/github_repos.txt',
	);

open my $repo_fh, '>:utf8', 'repos-processed.txt';
open my $user_fh, '>:utf8', 'users-processed.txt';
open my $errors_fh, '>:utf8', 'errors.txt';

my $count = 0;
my $fork_count = 0;

while( <> ) {
	chomp;

	my( $id, $user_repo ) = split;
	my( $user, $repo ) = split m|/|, $user_repo;

	my $path = catfile(
		substr( $user, 0, 1 ),
		substr( $user, 0, 2 ),
		$user,
		$repo
		);

	my( $first_found ) =
		grep { -e }
		map  { rel2abs( $path, $_ ) }
		( # The 100,000,000 files are spread out all over the place
		'.',
		'/Volumes/Micron ITb/github_repos',
		'/Volumes/Micron ITb/github_repos-big-scratch',
		'/Volumes/Big Scratch/github_repos',
		);

	unless( $first_found ) {
		say { $errors_fh } "Didn't find file for $_";
		next;
		}

	my $data = do {
		local $/;
		open my $fh, '<:raw', $first_found or do {
			warn "Could not open $first_found: $!";
			say { $errors_fh } "Could not open $first_found: $!";
			next;
			};
		<$fh>;
		};

	my $perl  = eval { decode_json $data };
	unless( $perl ) {
		say { $errors_fh } "JSON error for $first_found";
		next;
		}

	my $owner = $perl->{owner};

	my $string = join "\t",
		$perl->{'fork'},
		$user,
		$repo,
		$perl->{id},
		$perl->{private},
		$perl->{description},
		;

	$fork_count++ if $perl->{'fork'};

	printf "Processed: %d Forks %d (%.2f)\n",
		++$count,
		$fork_count,
		$fork_count / $count
		unless $count % 1000;

	say { $repo_fh } $string;
	say { $user_fh } join "\t",
		$owner->{id},
		$user,
		$perl->{gravatar_id},
		;

	}




__END__
{
"description":"Visualization tool for discrete Boltzmann distributions.",
"id":"15082042",
"full_name":"0/Boltzmannizer",
"private":false,
"fork":false,

"owner":{
	"id":140823,
	"login":"0",
	"site_admin":false,
	"gravatar_id":"",
	},
}
