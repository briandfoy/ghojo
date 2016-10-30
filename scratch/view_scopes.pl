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

repo  Full control of private repositories
  repo:status  Access commit status
  repo_deployment  Access deployment status
  public_repo  Access public repositories
admin:org  Full control of orgs and teams
  write:org  Read and write org and team membership
  read:org  Read org and team membership
admin:public_key  Full control of user public keys
  write:public_key  Write user public keys
  read:public_key  Read user public keys
admin:repo_hook  Full control of repository hooks
  write:repo_hook  Write repository hooks
  read:repo_hook  Read repository hooks
admin:org_hook  Full control of organization hooks
gist  Create gists
notifications  Access notifications
user  Update all user data
  user:email  Access user email addresses (read-only)
  user:follow  Follow and unfollow users
delete_repo  Delete repositories
admin:gpg_key  Full control of user gpg keys (Developer Preview)
  write:gpg_key  Write user gpg keys
  read:gpg_key  Read user gpg keys
