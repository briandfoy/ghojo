use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Endpoint::Reactions;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Reactions - The endpoints that deal with pull requests

=head1 SYNOPSIS


=head1 DESCRIPTION


* List users who reacted
* hash of reactions

	Reactions
		Commit Comment
		Issue
		Issue Comment
		Pull Request Review Comment


	content={+1,-1,laugh,confused,heart,hooray}

	application/vnd.github.squirrel-girl-preview

L<https://developer.github.com/v3/reactions/#reaction-types>

=head2 General reactions

=over 4

=item * delete_reaction( REACTION_ID )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::delete_reaction ( $self, $reaction_id ) {
	state $endpoint_profile = {
		params => {
			id => qr/\A\d+\z/,
			},
		};

	my $result = $self->delete_single_resource(
		endpoint         => '/reactions/:id',
		endpoint_params  =>  { id => $reaction_id },
		endpoint_profile => $endpoint_profile,
		bless_into       => 'Ghojo::Data::Reaction',
		);
	}

=back

=head2 Commit comment

=over 4

=item * list_reactions_for_commit( OWNER, REPO, COMMIT_ID [, CALLBACK] )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::list_reactions_for_commit ( $self, $owner, $repo, $id, $callback = sub { $_[0] } ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/comments/:id/reactions',
		endpoint_params => $params,
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Reaction',
		);
	}

=item * create_reaction_for_commit( OWNER, REPO, COMMIT_ID )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::create_reaction_for_commit ( $self, $owner, $repo, $id ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	my $result = $self->post_single_resource(
		endpoint        => '/repos/:owner/:repo/comments/:id/reactions',
		endpoint_params => $params,
		bless_into      => 'Ghojo::Data::Reaction',
		);
	}

=back

=head2 Issue

=over 4

=item * list_reactions_for_issue( OWNER, REPO, ISSUE_NUM [, CALLBACK] )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::list_reactions_for_issue ( $self, $owner, $repo, $id, $callback = sub { $_[0] } ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/issues',
		endpoint_params => $params,
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Reaction',
		);
	}

=item * create_reaction_for_issue( OWNER, REPO, ISSUE_NUM )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::create_reaction_for_issue ( $self, $owner, $repo, $id ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	my $result = $self->post_single_resource(
		endpoint        => '/repos/:owner/:repo/issues/:number/reactions',
		endpoint_params => $params,
		bless_into      => 'Ghojo::Data::Reaction',
		);
	}

=back

=head2 Issue comment

=over 4

=item * list_reactions_for_issue_comment( OWNER, REPO, COMMENT_ID [, CALLBACK] )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::list_reactions_for_issue_comment ( $self, $owner, $repo, $id, $callback ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/issues',
		endpoint_params => $params,
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Issue',
		);
	}

=item * create_reaction_for_issue_comment( OWNER, REPO, COMMENT_ID )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::create_reaction_for_issue_comment ( $self, $owner, $repo, $id ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	my $result = $self->post_single_resource(
		endpoint        => '/repos/:owner/:repo/issues/comments/:id/reactions',
		endpoint_params => $params,
		bless_into      => 'Ghojo::Data::Reaction',
		);
	}

=back

=head2 Pull request review comment

=over 4

=item * list_reactions_for_pull_request_comment( OWNER, REPO, COMMENT_ID [, CALLBACK] )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::list_reactions_for_pull_request_comment ( $self, $owner, $repo, $id, $callback = sub { $_[0] } ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/issues',
		endpoint_params => $params,
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Issue',
		);
	}

=item * create_reaction_for_pull_request_comment( OWNER, REPO, COMMENT_ID )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::create_reaction_for_pull_request_comment ( $self, $owner, $repo, $id ) {
	my $params = {
		owner => $owner,
		repo  => $repo,
		id    => $id,
		};

	my $result = $self->post_single_resource(
		endpoint        => '/repos/:owner/:repo/pulls/comments/:id/reactions',
		endpoint_params => $params,
		bless_into      => 'Ghojo::Data::Reaction',
		);
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
