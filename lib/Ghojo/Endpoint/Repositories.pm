use v5.26;

package Ghojo::Endpoint::Repositories;
use experimental qw(signatures);

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

use Ghojo::Mixins::QueryValidators;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Repositories - The endpoints that deal with repositories

=head1 SYNOPSIS


=head1 DESCRIPTION

	Repositories
		Branches
		Collaborators
		Comments
		Commits
		Contents
		Deploy Keys
		Deployments
		Downloads
		Forks
		Invitations
		Merging
		Pages
		Projects
		Releases
		Statistics
		Statuses
		Traffic
		Webhooks

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

This is a public API endpoint.


=cut

sub Ghojo::AuthenticatedUser::repos ( $self, $callback = sub { $_[0] }, $query = {} ) {
	$self->entered_sub;

	# handle type present with visibility or affiliation
	state $query_profile = {
		params => {
			visibility  => [ qw(public private all) ],
			affiliation => sub ( $s ) {
				state $allowed = { map { $_, 1 } qw( owner collaborator organization_member ) };
				my @parts = split /,/, $s;
				foreach my $part ( @parts ) {
					return 0 unless exists $allowed->{$part};
					}
				return 1;
				},
			type        => [ qw(all owner public private member) ],
			'sort'      => [ qw(created updated pushed full_name) ],
			direction   => [ qw(asc desc) ],
			},
		};

	my $perl = $self->get_paged_resources(
		endpoint      => '/user/repos',
		callback      => $callback,
		query_params  => $query,
		query_profile => $query_profile,
		);
	}


=item * Ghojo::PublicUser::get_repo ( OWNER, REPO )

The parent and source objects are present when the repository is a
fork. parent is the repository this repository was forked from, source
is the ultimate source for the network.

This is a public API endpoint.

L<https://developer.github.com/v3/repos/#list-your-repositories>

=cut

sub Ghojo::PublicUser::get_repo ( $self, $owner, $repo ) {
	$self->entered_sub;
	$self->get_single_resource(
		endpoint             => '/repos/:owner/:repo',
		endpoint_params      => { owner => $owner, repo => $repo },
		bless_into           => 'Ghojo::Data::Repo',
		);
	}

=item * repo_is_available( OWNER, REPO )

Return true is the repo is available, and false otherwise.

Repositories might be hidden or private, so they might appear to
not exist. The GitHub API purposedly does not distinguish between
hidden and non-existent repos.

You might want to use C<repo_check> instead. It will cache the result.

=cut

sub Ghojo::PublicUser::repo_is_available ( $self, $owner, $repo ) {
	$self->entered_sub;
	$self->get_repo( $owner, $repo )->is_success;
	}

=item * get_repos_for_username( USERNAME, CALLBACK, HASH_REF )

	type		enum{ all, owner*, member }
	sort		enum{ created, updated, pushed, full_name* }
	direction	enum{ asc, desc }

This is a public API endpoint.

L<https://developer.github.com/v3/repos/#list-user-repositories>

=cut

sub Ghojo::PublicUser::get_repos_for_username ( $self, $username, $callback = sub { $_[0] }, $query = {} ) {
	$self->entered_sub;

	state $query_profile = {
		params => {
			type      => [ qw(all owner member) ],
			'sort'    => [ qw(created updated pushed full_name) ],
			direction => [ qw(asc desc) ],
			},
		};

	$self->get_paged_resources(
		endpoint        => '/users/:username/repos',
		endpoint_params => { username => $username },
		query_params    => $query,
		query_profile   => $query_profile,
		bless_into      => 'Ghojo::Data::Repo',
		callback        => $callback,
		);
	}

=item * get_repos_owned_by( USER, CALLBACK, ARGS )

Like C<get_repos_for_username>, but only returns repos owned by the
user.

ARGS is a hash ref that may contain any of these parameters. However,
you can sort on anything you like when you get the L<Mojo::Collection>
back.

	sort		enum{ created, updated, pushed, full_name* }
	direction	enum{ asc, desc }

This is a public API endpoint.

L<https://developer.github.com/v3/repos/#list-user-repositories>

=cut

sub Ghojo::PublicUser::get_repos_owned_by ( $self, $username, $callback = sub { $_[0] }, $query = {} ) {
	$query->{type} = 'owner';
	$self->get_repos_for_username( $username, $callback, $query );
	}

=item * get_repos_with_member( USER, CALLBACK, ARGS )

Like C<get_repos_for_username>, but only returns repos where USER is
a member.

ARGS is a hash ref that may contain any of these parameters. However,
you can sort on anything you like when you get the L<Mojo::Collection>
back.

	sort		enum{ created, updated, pushed, full_name* }
	direction	enum{ asc, desc }

This is a public API endpoint.

L<https://developer.github.com/v3/repos/#list-user-repositories>

=cut

sub Ghojo::PublicUser::get_repos_with_member ( $self, $username, $callback = sub { $_[0] }, $query = {} ) {
	$query->{type} = 'member';
	$self->get_repos_for_username( $username, $callback, $query );
	}

=item * repos_by_organization

UNIMPLEMETED

GET /orgs/:org/repos
type	string	Can be one of all, public, private, forks, sources, member. Default: all

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::repos_by_organization( $self, $organization ) {
	$self->unimplemented;
	}

=item * all_public_repos( CALLBACK, QUERY_HASH )

UNIMPLEMETED

GET /repositories

	since	string	The integer ID of the last Repository that you've seen.

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::all_public_repos ( $self, $callback = sub {}, $query = {}, $args = {} ) {
	state $profile = {
		params => {
			since => qr/\A\[0-9]+\z/,
			},
		};

	$self->get_paged_resources(
		endpoint        => '/repositories',
		callback        => $callback,
		query_params    => $query,
		query_profile   => $profile,
		%$args,
		);
	}

=item * create_repo( )

	name                string	Required. The name of the repository
	description         string	A short description of the repository
	homepage            string	A URL with more information about the repository
	private             boolean	Either true to create a private repository, or false to create a public one. Creating private repositories requires a paid GitHub account. Default: false
	has_issues          boolean	Either true to enable issues for this repository, false to disable them. Default: true
	has_wiki            boolean	Either true to enable the wiki for this repository, false to disable it. Default: true
	has_downloads       boolean	Either true to enable downloads for this repository, false to disable them. Default: true
	auto_init           boolean	Pass true to create an initial commit with empty README. Default: false
	gitignore_template  string	Desired language or platform .gitignore template to apply. Use the name of the template without the extension. For example, "Haskell".
	license_template    string	Desired LICENSE template to apply. Use the name of the template without the extension. For example, "mit" or "mozilla".

	team_id             integer The id of the team that will be granted access to this repository. This is only valid when creating a repository in an organization.

gitignore_templates


license_templates


public_repo scope or repo scope to create a public repository
repo scope to create a private repository

=cut

sub Ghojo::AuthenticatedUser::create_repo ( $self, $repo, $callback = sub { $_[0] }, $query = {}, $args = {} ) {
	# https://docs.github.com/en/rest/reference/repos#create-a-repository-for-the-authenticated-user
	# POST /user/repos

	state $query_profile = {
		params => {
			name          => \&github_name,
			description   => \&basic_string,
			homepage      => \&url,
			private       => \&boolean,
			has_wiki      => \&boolean,
			has_downloads => \&boolean,
			auto_init     => \&boolean,

			gitignore_template => \&basic_string,
			license_template   => \&basic_string,
			},
		required => [ qw(name) ],
		};

	$args->{name} = $repo;

	$self->post_single_resource(
		endpoint        => '/user/repos',
		query_profile   => $query_profile,
		query_params    => $args,
		json            => $args,
		);
	}

sub Ghojo::AuthenticatedUser::create_repo_in_org ( $self ) {
	# POST /orgs/:org/repos
	$self->unimplemented;
	}


=item * edit_repo

UNIMPLEMETED

PATCH /repos/:owner/:repo

This is a public API endpoint.

=cut

sub Ghojo::AuthenticatedUser::edit_repo ( $self, $owner, $repo, $hash = {} ) {
	$self->unimplemented;
	}

=item * list_repo_contributors( OWNER, REPO )

UNIMPLEMETED

GET /repos/:owner/:repo/contributors

	anon	string	Set to 1 or true to include anonymous contributors in results.

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_repo_contributors ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * get_repo_languages

UNIMPLEMETED

GET /repos/:owner/:repo/languages

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_repo_languages ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * get_repo_teams

UNIMPLEMETED

GET /repos/:owner/:repo/teams

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_repo_teams ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * get_repo_tags

UNIMPLEMETED

GET /repos/:owner/:repo/tags

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_repo_tags ( $self, $owner, $repo ) {
	$self->unimplemented;
	}

=item * delete_repo

UNIMPLEMETED

DELETE /repos/:owner/:repo

Deleting a repository requires admin access. If OAuth is used, the delete_repo scope is required.

=cut

sub Ghojo::AuthenticatedUser::delete_repo ( $self, $owner, $repo ) {
	# https://docs.github.com/en/rest/reference/repos#delete-a-repository
	# DELETE /repos/{owner}/{repo}
	$self->entered_sub;

	state $endpoint_profile = {
		params => {
			owner => \&github_name,
			repo  => \&repo_name,
			},
		required => [ qw(owner repo) ],
		};

	$self->delete_single_resource(
		endpoint         => '/repos/:owner/:repo',
		endpoint_profile => $endpoint_profile,
		endpoint_params  => {
			owner => $owner,
			repo  => $repo,
			},
		required_scopes => [ qw(delete_repo) ],
		);
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
