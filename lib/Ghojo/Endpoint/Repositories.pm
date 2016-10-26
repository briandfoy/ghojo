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

sub Ghojo::PublicUser::get_repo ( $self, $owner, $repo ) {
	$self->entered_sub;
	$self->get_single_resource(
		$self->endpoint_to_url( '/repos/:owner/:repo', {owner => $owner, repo => $repo} ),
		bless_into           => 'Ghojo::Data::Repo',
		);
	}

=item * get_repos_for_username( USERNAME, CALLBACK, HASH_REF )

GET /users/:username/repos

	type		enum{ all, owner*, member }
	sort		enum{ created, updated, pushed, full_name* }
	direction	enum{ asc, desc }

=cut

sub Ghojo::PublicUser::get_repos_for_username( $self, $username, $callback = sub { $_[0] }, $args = {} ) {
	$self->entered_sub;

	my $profile = {
		type      => [ qw(all owner member) ],
		'sort'    => [ qw(created updated pushed full_name) ],
		direction => [ qw(asc desc) ],
		};

	my $result = $self->validate( $args, $profile );
	return $result if $result->is_error;

	my $query = $result->values->first;

	$self->get_paged_resources(
		$self->endpoint_to_url( '/users/:username/repos', { username => $username }, $query ),
		bless_into           => 'Ghojo::Data::Repo',
		callback             => $callback,
		);
	}

=item * repos_by_organization

GET /orgs/:org/repos
type	string	Can be one of all, public, private, forks, sources, member. Default: all

=cut

sub Ghojo::PublicUser::repos_by_organization( $self, $organization ) {
	$self->unimplemented;
	}

=item * all_public_repos( CALLBACK, QUERY_HASH )

GET /repositories

since	string	The integer ID of the last Repository that you've seen.

=cut

sub Ghojo::PublicUser::all_public_repos ( $self, $callback = sub {}, $query = {} ) {
	my $perl = $self->paged_get( '/repositories', [], $callback, $query );
	}

=item * edit_repo

	PATCH /repos/:owner/:repo

=cut

sub Ghojo::AuthenticatedUser::edit_repo( $self, $owner, $repo, $hash = {} ) {
	$self->unimplemented;
	}

=item * list_repo_contributors( OWNER, REPO )

GET /repos/:owner/:repo/contributors

anon	string	Set to 1 or true to include anonymous contributors in results.

=cut

sub Ghojo::PublicUser::get_repo_contributors ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * get_repo_languages

GET /repos/:owner/:repo/languages

=cut

sub Ghojo::PublicUser::get_repo_languages ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * get_repo_teams

GET /repos/:owner/:repo/teams

=cut

sub Ghojo::PublicUser::get_repo_teams ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * get_repo_tags

	GET /repos/:owner/:repo/tags


=cut

sub Ghojo::PublicUser::get_repo_tags ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * delete_repo

DELETE /repos/:owner/:repo

Deleting a repository requires admin access. If OAuth is used, the delete_repo scope is required.

=cut

sub Ghojo::AuthenticatedUser::delete_repo ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=back

=cut

__PACKAGE__
