use v5.26;

package Ghojo::Endpoint::DeploymentEnvironments;
use experimental qw(signatures);

our $VERSION = '1.001002';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::DeploymentEnvironments - The endpoints that deal with environments

=head1 SYNOPSIS


=head1 DESCRIPTION

	Gists
		Comments

=head2  General object thingys

=over 4

=item * list_environments

=cut

sub Ghojo::AuthenticatedUser::list_environments ( $self, $owner, $repo ) {
	$self->entered_sub;

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/environments',
		endpoint_params => {
			owner            => $owner,
			repo             => $repo,
			},
		bless_into      => 'Ghojo::Data::Environment',
		result_key      => 'environments',
		);
	}

=item * get_environment

=cut

sub Ghojo::AuthenticatedUser::get_environment ( $self, $owner, $repo, $environment_name ) {
	$self->entered_sub;

	$self->put_single_resource(
		endpoint        => '/repos/:owner/:repo/environments/:environment_name',
		endpoint_params => {
			owner            => $owner,
			repo             => $repo,
			environment_name => $environment_name,
			},
		);
	}

=item * create_environment( OWNER, REPO, NAME )

=item * update_environment

These are both the same things, and so far only create the environment
with the given name.

=cut

sub Ghojo::AuthenticatedUser::update_environment ( $self, $owner, $repo, $environment_name ) {
	$self->update_environment(  $owner, $repo, $environment_name );
	}

sub Ghojo::AuthenticatedUser::update_environment ( $self, $owner, $repo, $environment_name ) {
	$self->entered_sub;

	$self->update_single_resource(
		endpoint        => '/repos/:owner/:repo/environments/:environment_name',
		endpoint_params => {
			owner            => $owner,
			repo             => $repo,
			environment_name => $environment_name,
			},
		json => {},
		);
	}

=item * delete_environment

=cut

sub Ghojo::AuthenticatedUser::delete_environment ( $self, $owner, $repo, $environment_name ) {
	$self->entered_sub;

	$self->delete_single_resource(
		endpoint        => '/repos/:owner/:repo/environments/:environment_name',
		endpoint_params => {
			owner            => $owner,
			repo             => $repo,
			environment_name => $environment_name,
			},
		);
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2024, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
