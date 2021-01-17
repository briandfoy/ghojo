#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;
use Mojo::Util qw(dumper);

my( $owner, $repo ) = @ARGV;

my $ghojo = Ghojo->new({
	token => $ENV{GITHUB_TOKEN},
	});

my $result = $ghojo->list_workflow_runs( $owner, $repo );

foreach my $item ( $result->values->to_array->@* ) {
	state $id = $item->head_commit->id;
	last unless $id eq $item->head_commit->id;
	printf "%-10s %-10s %-10s %s\n",
		map( { $item->{$_} } qw(name status conclusion) ),
		$item->head_commit->message;

	}

