#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;
use Mojo::Util qw(dumper);

my( $repo ) = @ARGV;

my $ghojo = Ghojo->new({
	token => $ENV{GITHUB_TOKEN},
	});

my $result = $ghojo->create_repo( $repo );
say dumper( $result );
