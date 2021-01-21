use v5.32;
use lib qw(lib);

use Ghojo;

use Mojo::Util qw(dumper);

my $ghojo = Ghojo->new( { token => $ENV{GITHUB_TOKEN} } );
my $result = $ghojo->get_repo( @ARGV );

say dumper($result);
