#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;

my $ghojo = Ghojo->new( { token => shift } );

my $tx = $ghojo->ua->get( 'https://api.github.com/users/technoweenie' );
say $tx->res->to_string;

__END__
https://developer.github.com/v3/oauth/

X-OAuth-Scopes:
X-Accepted-OAuth-Scopes
