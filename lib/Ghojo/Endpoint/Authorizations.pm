use v5.24;
use experimental qw(signatures);

package Ghojo::Endpoint::Authorizations;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Authorizations - The endpoints that deal with authorizations and applications

=head1 SYNOPSIS


=head1 DESCRIPTION


L<https://developer.github.com/v3/oauth_authorizations/>

=head2  General object thingys

=over 4

=item * is_valid_scope( SCOPE )

Returns a list of all valid scopes.

L<https://developer.github.com/v3/oauth/#scopes>

=cut

sub Ghojo::valid_scopes ( $self ) {
	state $scopes = [ qw(
		user
		user:email
		user:follow
		public_repo
		repo
		repo_deployment
		repo:status
		delete_repo
		notifications
		gist
		read:repo_hook
		write:repo_hook
		admin:repo_hook
		admin:org_hook
		read:org
		write:org
		admin:org
		read:public_key
		write:public_key
		admin:public_key
		read:gpg_key
		write:gpg_key
		admin:gpg_key
		) ];
	}

=item * is_valid_scope( SCOPE )

Returns true if SCOPE is a valid authorization scope.

=cut

sub Ghojo::is_valid_scope ( $self, $scope ) {
	state $scopes = { map { lc $_, undef } $self->valid_scopes };
	exists $scopes->{ lc $scope };
	}

=item * has_scopes

Always returns true, so far.

=cut

sub Ghojo::has_scopes ( $self, $scopes ) {
	1;
	}

=back

=head2 Authorizations

=over 4

=item * get_authorizations( CALLBACK )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#list-your-authorizations>

=cut

sub Ghojo::AuthenticatedUser::get_authorizations ( $self, $callback = sub { $_[0] } ) {
	state $expected_status = 200;

	my $collection = $self->get_paged_resources(
		$self->endpoint_to_url( '/authorizations' ),
		bless_into           => 'Ghojo::Data::Grant',
		);
	}

=item * get_authorizations_by_id( LIST_OF_IDS )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#get-a-single-authorization>

=cut

sub Ghojo::AuthenticatedUser::get_authorizations_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, $self->get_single_resource(
			$self->endpoint_to_url( '/authorizations/:id', { id => $id } ),
			bless_into           => 'Ghojo::Data::Grant',
			);
		}

	Mojo::Collection->new( @results );
	}

=item * create_authorization( ARGS_HASH )

	scopes          array	A list of scopes that this authorization is in.
		user

		public_repo
		repo
		gist

	note            string	Required. A note to remind you what the OAuth token is for. Tokens not associated with a specific OAuth application (i.e. personal access tokens) must have a unique note.
	note_url        string	A URL to remind you what app the OAuth token is for.
	client_id       string	The 20 character OAuth app client key for which to create the token.
	client_secret	string	The 40 character OAuth app client secret for which to create the token.
	fingerprint     string	A unique string to distinguish an authorization from others created for the same client ID and user.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#create-a-new-authorization>

=cut

sub Ghojo::AuthenticatedUser::create_authorization ( $self, %args ) {
	state $query_url = $self->query_url( "/authorizations" );
	state $allowed   = [ qw(scopes note note_url client_id client_secret fingerprint) ];
	state $required  = [ qw(note) ];

	$args{scopes} //= ['user', 'public_repo', 'repo', 'gist'];
	$args{note}   //= 'test purpose ' . time;

	$self->post_single_resource(
		$self->endpoint_to_url( '/authorizations' ),
		bless_into           => 'Ghojo::Data::Grant',
		data                 => \%args,
		);

	$self->token;
	}

=item * get_or_create_client_app_authorization( CLIENT, ARGS_HASH )

	client_secret   string  Required. The 40 character OAuth app client secret associated with the client ID specified in the URL.
	scopes          array   A list of scopes that this authorization is in.
	note            string  A note to remind you what the OAuth token is for.
	note_url        string  A URL to remind you what app the OAuth token is for.
	fingerprint     string  A unique string to distinguish an authorization from others created for the same client and user. If provided, this API is functionally equivalent to Get-or-create an authorization for a specific app and fingerprint.

	200 - Existing token
	201 - New token

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#get-or-create-an-authorization-for-a-specific-app>

=cut

sub Ghojo::AuthenticatedUser::get_or_create_client_app_authorization ( $self, $client_id, %args ) {
	$self->put_single_resource(
		$self->endpoint_to_url( '/authorizations/clients/:client_id',{ client_id => $client_id } ),
		bless_into           => 'Ghojo::Data::Grant',
		expected_http_status => [ 200, 201 ],
		data                 => \%args,
		);
	}

=item * update_authorization

UNIMPLEMENTED

You can only send one of these scope keys at a time

	scopes	array	Replaces the authorization scopes with these.
	add_scopes	array	A list of scopes to add to this authorization.
	remove_scopes	array	A list of scopes to remove from this authorization.

	note	string	A note to remind you what the OAuth token is for. Tokens not associated with a specific OAuth application (i.e. personal access tokens) must have a unique note.
	note_url	string	A URL to remind you what app the OAuth token is for.
	fingerprint	string	A unique string to distinguish an authorization from others created for the same client ID and user.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#update-an-existing-authorization>

=cut

# PATCH /authorizations/:id
# 200
sub Ghojo::AuthenticatedUser::update_authorization ( $self ) {
	$self->not_implemented;
	}

=item *

UNIMPLEMENTED

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#delete-an-authorization>

=cut

sub Ghojo::AuthenticatedUser::delete_gpg_keys_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, { id => $self->delete_single_resource(
			$self->endpoint_to_url( '/authorizations/:id', { id => $id } ),
			) };
		}

	Mojo::Collection->new( @results );
	}

=item *

UNIMPLEMENTED

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#check-an-authorization>

=cut

# must use basic auth
	# username => client_id
	# password => client_secret
sub Ghojo::AuthenticatedUser::check_authorization ( $self ) {
	$self->not_implemented;
	}


=back

=head2 Applications

=over 4

=item * get_grants( CALLBACK )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#list-your-grants>

=cut

sub Ghojo::AuthenticatedUser::get_grants ( $self, $callback = sub { $_[0] } ) {
	state $expected_status = 200;

	my $collection = $self->get_paged_resources(
		$self->endpoint_to_url( '/applications/grants' ),
		bless_into           => 'Ghojo::Data::Grant',
		);
	}

=item * get_grants_by_id( LIST_OF_IDS )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#get-a-single-grant>

=cut

sub Ghojo::AuthenticatedUser::get_grants_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, $self->get_single_resource(
			$self->endpoint_to_url( '/applications/grants/:id', { id => $id } ),
			bless_into           => 'Ghojo::Data::Grant',
			);
		}

	Mojo::Collection->new( @results );
	}

=item * reset_app_authorization

UNIMPLEMENTED

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#reset-an-authorization>

=cut

# must use Basic Auth
	# username => client_id
	# password => client_secret
sub Ghojo::AuthenticatedUser::reset_app_authorization ( $self, $client_id, $access_token ) {
	# POST /applications/:client_id/tokens/:access_token
	# 200
	$self->not_implemented;
	}

=item * revoke_app_authorization( CLIENT_ID, ACCESS_TOKEN )

UNIMPLEMENTED

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#revoke-an-authorization-for-an-application>

=cut

# must use Basic Auth
	# username => client_id
	# password => client_secret
sub Ghojo::AuthenticatedUser::revoke_app_authorization ( $self, $client_id, $access_token ) {
	$self->not_implemented;
	}

=item * revoke_grant( CLIENT_ID, ACCESS_TOKEN )

UNIMPLEMENTED

This is an authenticated API endpoint.

L<https://developer.github.com/v3/oauth_authorizations/#revoke-a-grant-for-an-application>

=cut

# must use Basic Auth
	# username => client_id
	# password => client_secret
sub Ghojo::AuthenticatedUser::revoke_grant ( $self, $client_id, $access_token ) {
	$self->not_implemented;
	}

=back

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
