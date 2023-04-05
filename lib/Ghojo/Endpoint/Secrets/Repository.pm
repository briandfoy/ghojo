use v5.26;

package Ghojo::Endpoint::Actions::Secrets::Repository;
use experimental qw(signatures);

our $VERSION = '1.001002';

use Mojo::Collection;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Actions::Secrets::Repository - The endpoints that deal with repository secrets

=head1 SYNOPSIS

	use Ghojo;

	my $ghojo = Ghojo->new( ... );

	my $result = $ghojo->list_secrets( $owner, $repo );
	if( $result->is_success ) {
		my $secrets = $result->values;  # A Mojo::Collection object
		}

=head1 DESCRIPTION

This section implements the endpoints that deal with repository secrets.

=head2 Secrets

=over 4

=item * list_secrets

Return a list of secrets. These do not actually return the secret. It
gets the secret name, the creation date, and the update date.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::list_secrets ( $self, $owner, $repo, $callback = sub { $_[0] }, $query = {} ) {
	$self->entered_sub;

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/actions/secrets',
		endpoint_params => { owner => $owner, repo => $repo },
		callback        => $callback,
		query_profile   => {
			params => {
				per_page  => \&per_page_number,
				page      => \&page_number,
				},
			},
		query           => $query,
		);
	}

=item * get_public_key

Get the public key and key id for the repository. This is mostly used
in C<create_secret>, so you typically don't need to use this
directly.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::get_public_key ( $self, $owner, $repo ) {
	$self->entered_sub;

	$self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/actions/secrets/public-key',
		endpoint_params => { owner => $owner, repo => $repo },
		bless_into      => 'Ghojo::Data::SecretPublicKey',
		);

	}


=item * get_secret( OWNER, REPO, SECRET_NAME )

Fetch a particular secret. The returned hash has the secret name,
creation date, and update date. You do not get back the secret
text.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::get_secret ( $self, $owner, $repo, $name ) {
	$self->entered_sub;

	$self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/actions/secrets/:secret_name',
		endpoint_params => { owner => $owner, repo => $repo, secret_name => $name },
		bless_into      => 'Ghojo::Data::Secret',
		);
	}

=item * create_secret( OWNER, REPO, SECRET_NAME, SECRET_VALUE )

=item * update_secret( OWNER, REPO, SECRET_NAME, SECRET_VALUE )

Create or update the secret with name SECRET_NAME and value SECRET_VALUE.
These are handled by the same function, and the API doesn't care if
you update a secret that doesn't yet exist.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::create_secret ( $self, $owner, $repo, $name, $value ) {
	$self->entered_sub;

	$self->logger->debug( "name is <$name>" );
	$self->logger->debug( "value is <$value>" );

	my $public_key = $self->get_public_key( $owner, $repo );
	my $public_key_base64 = $public_key->values->[0]{key};

	my $encrypted = _nacl_encrypt($value, $public_key_base64);

	my $args = {
		encrypted_value => $encrypted,
		key_id => $public_key->values->[0]{key_id},
		};
	$self->logger->debug( "args are " . Mojo::Util::dumper($args) );

	$self->put_single_resource(
		endpoint        => '/repos/:owner/:repo/actions/secrets/:secret_name',
		endpoint_params => { owner => $owner, repo => $repo, secret_name => $name },
		bless_into      => 'Ghojo::Data::Secret',
		expected_http_status => [ qw(201 204) ],
		json => $args,
		);
	}

=item * delete_secret( OWNER, REPO, SECRET_NAME )

Delete the secret.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::delete_secret ( $self, $owner, $repo, $name ) {
	$self->entered_sub;

	$self->delete_single_resource(
		endpoint        => '/repos/:owner/:repo/actions/secrets/:secret_name',
		endpoint_params => {
			owner        => $owner,
			repo         => $repo,
			secret_name  => $name,
			},
		expected_http_status => [ qw(201 204) ],
		);
	}


sub _nacl_encrypt ($plain, $public_key_base64) {
	state $rc =	require Sodium::FFI;
	my $key_bin = Sodium::FFI::sodium_base642bin($public_key_base64);
	my $crypted = Sodium::FFI::crypto_box_seal( $plain, $key_bin );
	return Sodium::FFI::sodium_bin2base64($crypted);
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2023, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__;
