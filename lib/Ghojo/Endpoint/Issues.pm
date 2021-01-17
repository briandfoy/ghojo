use v5.26;

package Ghojo::Endpoint::Issues;
use experimental qw(signatures);

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Issues - The endpoints that deal with issues

=head1 SYNOPSIS


=head1 DESCRIPTION

	Issues
		Assignees
		Comments
		Events
		Labels
		Milestones
		Timeline

=head2 Issues


application/vnd.github.VERSION.raw+json
application/vnd.github.VERSION.text+json
application/vnd.github.VERSION.html+json
application/vnd.github.VERSION.full+json

=over 4

=item * issuess_on_repo( USER, REPO, CALLBACK, HASHREF )

=item * all_issuess_on_repo( USER, REPO, CALLBACK, HASHREF )

=item * open_issuess_on_repo( USER, REPO, CALLBACK, HASHREF )

=item * closed_issuess_on_repo( USER, REPO, CALLBACK, HASHREF )

Get the information for all the labels of a repo.

The keys of the HASHREF can be:

	milestone   integer     If an integer is passed, it should
	            or string   refer to a milestone by its number field.
	                        If the string * is passed, issues
	                        with any milestone are accepted.
	                        If the string none is passed, issues
	                        without milestones are returned.

	state       string      Indicates the state of the issues
	                        to return. Can be either open, closed,
	                        or all. Default: open

	assignee    string      Can be the name of a user. Pass in
	                        none for issues with no assigned user,
	                        and * for issues assigned to any user.

	creator     string      The user who created the issue.

	mentioned   string      A user who's mentioned in the issue.

	labels      string      A list of comma separated label names.
	                        Example: bug,ui,@high

	sort        string      What to sort results by. Can be either created,
	                        updated, comments. Default: created

	direction   string      The direction of the sort. Can be either
	                        asc or desc. Default: desc

	since       string      Only issues updated at or after this time
	                        are returned. This is a timestamp in ISO
	                        8601 format: YYYY-MM-DDTHH:MM:SSZ.

=cut

sub Ghojo::get_repo_issues_profile ( $self ) {
	state $profile = {
		params => {
			milestone   => qr/\A (\*|none|\d+) \z/x,
			'state'     => [ qw(open closed all) ],
			assignee    => qr/\A (\*|none|\S+) \z/x,
			creator     => sub { defined $_[0] },
			mentioned   => sub { defined $_[0] },
			labels      => sub { 1 },
			'sort'      => [ qw(created updated comments) ],
			direction   => [ qw(asc desc) ],
			since       => sub { Ghojo::Type->is_iso8601( $_[0] ) },
			},
		required => [],
		};
	}

sub Ghojo::get_all_issues_profile ( $self ) {
	state $profile = {
		params => {
			filter      => [ qw(assigned created mentioned subscribed all) ],
			'state'     => [ qw(open closed all) ],
			labels      => sub { 1 },
			'sort'      => [ qw(created updated comments) ],
			direction   => [ qw(asc desc) ],
			since       => sub { Ghojo::Type->is_iso8601( $_[0] ) },
			},
		required => [],
		};
	}

sub Ghojo::PublicUser::issues_on_repo ( $self, $owner, $repo, $callback = sub { $_[0] } , $args = { 'state' => 'open' } ) {
	$self->entered_sub;

	my $repo_check_result = $self->check_repo( $owner, $repo );
	return $repo_check_result if $repo_check_result->is_error;

	my $result = $self->validate_profile( $args, $self->get_repo_issues_profile );
	return $result if $result->is_error;

	$self->get_paged_resources(
		endpoint        => "/repos/:owner/:repo/issues",
		endpoint_params => { owner => $owner, repo => $repo },
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Issue',
		query_params    => $args,
		query_profile   => $self->get_all_issues_profile,
		);
	}

sub Ghojo::PublicUser::all_issues_on_repo ( $self, $owner, $repo, $callback = sub { $_[0] }, $args = {} ) {
	$args->{'state'} = 'all';
	$self->issues_on_repo( $owner, $repo, $callback, $args );
	}

sub Ghojo::PublicUser::open_issuess_on_repo ( $self, $owner, $repo, $callback = sub { $_[0] }, $args = {} ) {
	$args->{'state'} = 'open';
	$self->issues_on_repo( $owner, $repo, $callback, $args );
	}

sub Ghojo::PublicUser::closed_issuess_on_repo ( $self, $owner, $repo, $callback = sub { $_[0] }, $args = {} ) {
	$args->{'state'} = 'closed';
	$self->issues_on_repo( $owner, $repo, $callback, $args );
	}

=item * get_issue_by_number( USER, REPO, NUMBER )

Get the information for a particular issue.

This is a public API endpoint.

L<https://developer.github.com/v3/issues/#get-a-single-issue>

=cut

sub Ghojo::PublicUser::get_issue_by_number ( $self, $owner, $repo, $number ) {
	$self->get_single_resource(
		endpoint   => '/repos/:owner/:repo/issues/:id',
		endpoint_params => {
			owner => $owner,
			repo  => $repo,
			id    => $number },
		bless_into => 'Ghojo::Data::Issue',
		accepts    => 'application/vnd.github.squirrel-girl-preview',
		);
	}

=item * issue_exists( USER, REPO, NUMBER )

=cut

sub Ghojo::PublicUser::issue_exists ( $self, $owner, $repo, $number ) {
	$self->get_issue_by_number( $owner, $repo, $number )->is_success;
	}

=item * issue_is_open( USER, REPO, NUMBER )

=cut

sub Ghojo::PublicUser::issue_is_open ( $self, $owner, $repo, $number ) {
	! $self->issue_is_closed( $owner, $repo, $number );
	}

=item * issue_is_closed( USER, REPO, NUMBER )

=cut

sub Ghojo::PublicUser::issue_is_closed ( $self, $owner, $repo, $number ) {
	my $result = $self->get_issue_by_number( $owner, $repo, $number );
	return $result if $result->is_error;

	defined $result->values->first->{closed_at};
	}

=item * get_issues_owned_by_you()

List all issues assigned to the authenticated user across all visible
repositories including owned repositories, member repositories, and
organization repositories.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#list-issues>

=cut

sub Ghojo::AuthenticatedUser::get_issues_owned_by_you ( $self, $callback = sub { $_[0] }, $args = {} ) {
	my $result = $self->validate_profile( $args, $self->get_all_issues_profile );
	return $result if $result->is_error;

	$self->get_paged_resources(
		endpoint   => '/issues',
		bless_into => 'Ghojo::Data::Issue',
		callback   => $callback,
		accepts    => 'application/vnd.github.squirrel-girl-preview',
		);
	}

=item * get_issues_owned_by_you()

List all issues across owned and member repositories assigned to
the authenticated user:

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#list-issues>

=cut

sub Ghojo::AuthenticatedUser::get_issues_owned_by_you2 ( $self, $callback = sub { $_[0] }, $args = {} ) {
	my $result = $self->validate_profile( $args, $self->get_all_issues_profile );
	return $result if $result->is_error;

	$self->get_paged_resources(
		endpoint   => '/issues',
		bless_into => 'Ghojo::Data::Issue',
		callback   => $callback,
		accepts    => 'application/vnd.github.squirrel-girl-preview',
		);
	}

=item * get_issues_in_org_owned_by_you( ORGANIZATION, CALLBACK, ARGS )

List all issues for a given organization assigned to the authenticated user:

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#list-issues>

=cut

sub Ghojo::AuthenticatedUser::get_issues_in_org_owned_by_you ( $self, $organization, $callback = sub { $_[0] }, $args = {} ) {
	my $result = $self->validate_profile( $args, $self->get_all_issues_profile );
	return $result if $result->is_error;

	$self->get_paged_resources(
		endpoint   => '/orgs/:org/issues',
		endpoint_params => { org => $organization },
		bless_into => 'Ghojo::Data::Issue',
		callback   => $callback,
		accepts    => 'application/vnd.github.squirrel-girl-preview',
		);
	}

=item * create_an_issue( OWNER, REPO, ARGS )

POST /repos/:owner/:repo/issues

	title       string Required.   The title of the issue.
	body        string	           The contents of the issue.
	# assignee    string	           Login for the user that this issue should be assigned to. NOTE: Only users with push access can set the assignee for new issues. The assignee is silently dropped otherwise. This field is deprecated.
	milestone   integer	           The number of the milestone to associate this issue with. NOTE: Only users with push access can set the milestone for new issues. The milestone is silently dropped otherwise.
	labels      array of strings   Labels to associate with this issue. NOTE: Only users with push access can set labels for new issues. Labels are silently dropped otherwise.
	assignees	array of strings   Logins for Users to assign to this issue. NOTE: Only users with push access can set assignees for new issues. Assignees are silently dropped otherwise.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#create-an-issue>

=cut

sub Ghojo::AuthenticatedUser::create_an_issue ( $self, $owner, $repo, $args = {} ) {
	$self->entered_sub;

	state $profile = {
		params => {
			title     => qr/\S/,
			body      => qr/\S/,
			milestone => sub { $self->has_push_access( $owner, $repo ) and $_[0] =~ m/\A[0-9]+\z/ },
			labels    => sub { $self->has_push_access( $owner, $repo ) and ref $_[0] eq ref [] },
			# also check that the users exist?
			assignees => sub { $self->has_push_access( $owner, $repo ) and ref $_[0] eq ref [] },
			},
		required => [ qw(title) ],
		};

	my $result = $self->validate_profile( $args, $profile );
	return $result if $result->is_error;

	$self->post_single_resource(
		endpoint => '/repos/:owner/:repo/issues',
		endpoint_params => {
			owner  => $owner,
			repo   => $repo,
			},
		json => $args,
		);
	}

=item * edit_an_issue

PATCH /repos/:owner/:repo/issues/:number

Issue owners and users with push access can edit an issue.


	title       string	           The title of the issue.
	body        string	           The contents of the issue.
	assignee	string	           Login for the user that this issue should be assigned to. This field is deprecated.
	milestone   integer	           The number of the milestone to associate this issue with or null to remove current. NOTE: Only users with push access can set the milestone for issues. The milestone is silently dropped otherwise.
	labels      array of strings   Labels to associate with this issue. Pass one or more Labels to replace the set of Labels on this Issue. Send an empty array ([]) to clear all Labels from the Issue. NOTE: Only users with push access can set labels for issues. Labels are silently dropped otherwise.
	assignees   array of strings   Logins for Users to assign to this issue. Pass one or more user logins to replace the set of assignees on this Issue. .Send an empty array ([]) to clear all assignees from the Issue. NOTE: Only users with push access can set assignees for new issues. Assignees are silently dropped otherwise.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#edit-an-issue>

=cut

sub Ghojo::AuthenticatedUser::edit_an_issue ( $self, $owner, $repo, $number, $args = {} ) {
	$self->entered_sub;

	state $profile = {
		params => {
			title     => qr/\S/,
			body      => qr/\S/,
			milestone => sub { $self->has_push_access( $owner, $repo ) and $_[0] =~ m/\A[0-9]+\z/ },
			labels    => sub { $self->has_push_access( $owner, $repo ) and ref $_[0] eq ref [] },
			# also check that the users exist?
			assignees => sub { $self->has_push_access( $owner, $repo ) and ref $_[0] eq ref [] },
			},
		required => [ qw(title) ],
		};

	my $result = $self->validate_profile( $args, $profile );
	return $result if $result->is_error;

	$self->patch_single_resource(
		endpoint => '/repos/:owner/:repo/issues/:number',
		endpoint_params => {
			owner  => $owner,
			repo   => $repo,
			number => $number,
			},
		json => $args,
		);
	}

=item * lock_an_issue

Users with push access can lock an issue's conversation.

PUT /repos/:owner/:repo/issues/:number/lock

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#lock-an-issue>

=cut

sub Ghojo::AuthenticatedUser::lock_an_issue ( $self, $owner, $repo, $number ) {
	$self->put_single_resource(
		endpoint => '/repos/:owner/:repo/issues/:number/lock',
		endpoint_params => {
			owner => $owner,
			repo  => $repo,
			number => $number },
		expected_http_status => 204,
		);
	}

=item * unlock_an_issue

Users with push access can unlock an issue's conversation.

DELETE /repos/:owner/:repo/issues/:number/lock

This is an authenticated API endpoint.

L<https://developer.github.com/v3/issues/#unlock-an-issue>

=cut

sub Ghojo::AuthenticatedUser::unlock_an_issue ( $self, $owner, $repo, $number ) {
	$self->delete_single_resource(
		endpoint => '/repos/:owner/:repo/issues/:number/lock',
		endpoint_params  => {
			owner => $owner,
			repo  => $repo,
			number => $number },
		);
	}

=back

=head1 Comments

POST /repos/:owner/:repo/issues/:number/comments

body	string	Required. The contents of the comment.

=cut

sub Ghojo::AuthenticatedUser::create_issue_comment ( $self, $owner, $repo, $number, $args ) {
	$self->entered_sub;

	state $profile = {
		params => {
			body      => qr/\S/,
			},
		required => [ qw(body) ],
		};

	$self->post_single_resource(
		endpoint => '/repos/:owner/:repo/issues/:number/comments',
		endpoint_params  => {
			owner         => $owner,
			repo          => $repo,
			number        => $number,
			},
		json          => $args,
		query_profile => $profile,

		);
	}

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__

__END__
