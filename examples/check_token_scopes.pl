use v5.32;
use lib qw(lib);
use Ghojo;

=head1 NAME

check_token_scopes.pl - Show which scopes a GitHub Personal Access Token has

=head1 SYNOPSIS

	% perl check_token_scopes.pl TOKEN

=head1

=cut

my( $token ) = @ARGV;
die "No token!" unless $token;

my $ghojo = Ghojo->new( { token => $token } );
die "There is an error: " . $ghojo->message . "\n" if $ghojo->is_error;

my $result = $ghojo->get_authenticated_user;
if( $result->is_error ) {
	die "Could not get the authenticated user\n";
	}

say "Response scopes: ", join ' ', sort $result->extras->{has_scopes}->@*;
say "Object scopes:   ", join ' ', sort $ghojo->scopes->as_list;
