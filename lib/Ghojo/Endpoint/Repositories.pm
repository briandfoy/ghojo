use v5.24.0;
use feature qw(signatures);
no warnings qw(experimental::signatures);

=encoding utf8

=head2 Repositories

=over 4

=item * repos

GET /user/repos

	visibility      string
	    Can be one of all, public, or private.
	    Default: all

	affiliation     string	Comma-separated list of values. Can include:
	    * owner
	    * collaborator
	    * organization_member
		Default: owner,collaborator,organization_member

	type            string
		Can be one of all, owner, public, private, member.
		Default: all

	    Will cause a 422 error if used in the same request as
	    visibility or affiliation.

	sort            string
		Can be one of created, updated, pushed, full_name.
		Default: full_name

	direction       string
		Can be one of asc or desc.
		Default: when using full_name: asc; otherwise desc

=cut

sub repos ( $self, $callback = sub {}, $query = {} ) {
	$self->logger->trace( 'In repos' );
	my $perl = $self->paged_get( '/user/repos', [], $callback, $query );
	}


=item * get_repo ( OWNER, REPO )

GET /repos/:owner/:repo

The parent and source objects are present when the repository is a
fork. parent is the repository this repository was forked from, source
is the ultimate source for the network.

=cut

sub get_repo ( $self, $owner, $repo ) {
	state $expected_status = 200;

	my $url = $self->query_url( '/repos/%s/%s', [ $owner, $repo ] );
	my $tx  = $self->ua->get( $url );

	unless( $tx->res->code == $expected_status ) {
		my $json = $tx->res->json;
		if( $json->{message} eq 'Not Found' ) {
			$self->logger->error( "get_repo: repo $owner/$repo was not found" );
			}
		else {
			$self->logger->error( "get_repo: unspecified error looking for $owner/$repo. Code " . $tx->res->code );
			$self->logger->debug( "get_repo: " . $tx->res->body );
			}
		return;
		}

	my $perl = $tx->res->json;
	}

=item * repos_by_username( USERNAME )

GET /users/:username/repos

type	string	Can be one of all, owner, member. Default: owner
sort	string	Can be one of created, updated, pushed, full_name. Default: full_name
direction	string	Can be one of asc or desc. Default: when using full_name: asc, otherwise desc

=cut

sub repos_by_username( $self, $username ) {
	$self->paged_get( '', [ $username ] );

	}

=item * repos_by_organization

GET /orgs/:org/repos
type	string	Can be one of all, public, private, forks, sources, member. Default: all

=cut

sub repos_by_organization( $self, $organization ) {


	}

=item * all_public_repos( CALLBACK, QUERY_HASH )

GET /repositories

since	string	The integer ID of the last Repository that you've seen.

=cut

sub all_public_repos ( $self, $callback = sub {}, $query = {} ) {
	my $perl = $self->paged_get( '/repositories', [], $callback, $query );
	}

=item * edit_repo

	PATCH /repos/:owner/:repo

=cut

sub edit_repo( $self, $owner, $repo, $hash = {} ) {

	}

=item * list_repo_contributors( OWNER, REPO )

GET /repos/:owner/:repo/contributors

anon	string	Set to 1 or true to include anonymous contributors in results.

=cut

sub get_repo_contributors ( $self, $owner, $repo ) {


	}

=item * get_repo_languages

GET /repos/:owner/:repo/languages

=cut

sub get_repo_languages ( $self, $owner, $repo ) {


	}

=item * get_repo_teams

GET /repos/:owner/:repo/teams

=cut

sub get_repo_teams ( $self, $owner, $repo ) {


	}

=item * get_repo_tags

	GET /repos/:owner/:repo/tags


=cut

sub get_repo_tags ( $self, $owner, $repo ) {


	}

=item * delete_repo

DELETE /repos/:owner/:repo

Deleting a repository requires admin access. If OAuth is used, the delete_repo scope is required.

=cut

sub delete_repo ( $owner, $repo ) {

	}

=back

=cut

__PACKAGE__
