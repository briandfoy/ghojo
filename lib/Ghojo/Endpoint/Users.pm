use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Endpoint::Users;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::User - The endpoints that deal with user information and relationships

=head1 SYNOPSIS


=head1 DESCRIPTION

	Users
		Emails
		Followers
		Git SSH Keys
		GPG Keys
		Administration (Enterprise)

=head2  General object thingys

=head2 Users

=over 4

=item * get_authenticated_user()

Returns a hash reference representing the authenticated user.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/users/#get-the-authenticated-user>

=cut

sub Ghojo::AuthenticatedUser::get_authenticated_user ( $self ) {
	$self->logger->trace( 'Getting the authenticated user record' );

	$self->get_single_resource(
		endpoint   => '/user',
		bless_into => 'Ghojo::Data::UserRecord',
		);
	}

=item * get_user( USERNAME )

Returns a hash reference representing the requested user.

This is a public API endpoint.

L<https://developer.github.com/v3/users/#get-a-single-user>

=cut

sub Ghojo::PublicUser::get_user ( $self, $user ) {
	$self->entered_sub;
	$self->get_single_resource(
		endpoint        => '/users/:username',
		endpoint_params => { username => $user },
		bless_into      => 'Ghojo::Data::UserRecord',
		);
	}

=item * user_is_available( USER )

You might want to use C<repo_check> instead. It will cache the result.

=cut

sub Ghojo::PublicUser::user_is_available ( $self, $user ) {
	$self->entered_sub;
	$self->get_user( $user )->is_success;
	}

=item * get_all_users( CALLBACK )

This will eventually return millions of rows! The public API can use
this, but you have a limit of 60 requests per hour. That's going to
take a long time.

This is a public API endpoint.

L<https://developer.github.com/v3/users/#get-all-users>

=cut

sub Ghojo::PublicUser::get_all_users ( $self, $callback = sub { $_[0] } ) {
	$self->entered_sub;
	my $result = $self->get_paged_resources(
		endpoint   => '/users',
		bless_into => 'Ghojo::Data::UserRecord',
		callback   => $callback,
		);
	}

=item * update_user( ARGS )

	name        string	The new name of the user
	email       string	Publicly visible email address.
	blog        string	The new blog URL of the user.
	company     string	The new company of the user.
	location    string	The new location of the user.
	hireable    boolean	The new hiring availability of the user.
	bio         string	The new short biography of the user.

This is an authenticated API endpoint.

L<https://developer.github.com/v3/users/#update-the-authenticated-user>

=cut

sub Ghojo::AuthenticatedUser::update_user ( $self, $args = {} ) {
	state $allowed_fields = [
		qw(name
		email
		blog
		company
		location
		hireable
		bio)
		];

	return Ghojo::Result->error( {
		description => 'Update the authenticated user',
		message     => 'Argument should have been a hash reference, but was not',
		error_code  => 4,
		extras      => {
			args => [ @_ ]
			},
		} ) unless ref $args eq ref {};

	my %data = map {
		exists $args->{$_}
			?
		($_ => $args->{$_})
			:
			()
		} $allowed_fields->@*;

	if( exists $data{hireable} ) {
		$data{hireable} ? \1 : \0 # This is how Mojo::JSON handles booleans
		};

	$self->patch_single_resource(
		endpoint   => '/user',
		bless_into => 'Ghojo::Data::UserRecord',
		data       => \%data,
		);
	}

=back

=head2 Configured email addresses for the authenticated user

=over 4

=item * get_authenticated_user_emails( CALLBACK )

Returns a L<Mojo::Collection> object of emails for the authenticated in user:

	{
	"email": "octocat@github.com",
	"verified": true,
	"primary": true
	}


This is an authenticated API endpoint. It requires the C<user:email>
scope.

L<https://developer.github.com/v3/users/emails/#list-email-addresses-for-a-user>

=cut

sub Ghojo::AuthenticatedUser::get_authenticated_user_emails ( $self, $callback = sub { $_[0] } ) {
	my $collection = $self->get_paged_resources(
		endpoint       => '/user/emails',
		requires_scope => [ qw(user:email) ],
		bless_into     => 'Ghojo::Data::Email',
		);
	}

=item * add_authenticated_user_emails( LIST_OF_EMAILS )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/users/emails/#add-email-addresses>

=cut

sub Ghojo::AuthenticatedUser::add_authenticated_user_emails ( $self, @emails ) {
	my $collection = $self->post_paged_resources(
		endpoint    => '/user/emails',
		bless_into  => 'Ghojo::Data::Email',
		data        => \@emails,
		);
	}

=item * delete_authenticated_user_emails( LIST_OF_EMAILS )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/users/emails/#delete-email-addresses>

=cut

sub Ghojo::AuthenticatedUser::delete_authenticated_user_emails ( $self, @emails ) {
	my $collection = $self->delete_resources(
		endpoint => '/user/emails',
		data     => \@emails,
		);
	}

=back

=head2 Followers

=over 4

=item * get_followers_of_user( CALLBACK )

This is a public API endpoint.

L<https://developer.github.com/v3/users/followers/#list-followers-of-a-user>

=cut

sub Ghojo::PublicUser::get_followers_of_user ( $self, $user, $callback = sub { $_[0] } ) {
	my $collection = $self->get_paged_resources(
		endpoint        => '/user/following/:username',
		endpoint_params => {username => $user},
		bless_into      => 'Ghojo::Data::UserRecord',
		);
	}

=item * get_your_followers( CALLBACK )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/users/followers/#list-followers-of-a-user>

=cut

sub Ghojo::AuthenticatedUser::get_your_followers ( $self, $callback = sub { $_[0] } ) {
	my $collection = $self->get_paged_resources(
		endpoint   => '/user/followers',
		bless_into => 'Ghojo::Data::UserRecord',
		);
	}

=item * get_users_followed_by_another( USER, CALLBACK )

This is a public API endpoint.

L<https://developer.github.com/v3/users/followers/#list-users-followed-by-another-user>

=cut

sub Ghojo::PublicUser::get_users_followed_by_another ( $self, $user, $callback = sub { $_[0] } ) {
	my $collection = $self->get_paged_resources(
		endpoint        => '/user/:username/following',
		endpoint_params => {username => $user},
		bless_into      => 'Ghojo::Data::UserRecord',
		);
	}

=item * you_are_following( USER )

This is an authenticated API endpoint.

L<https://developer.github.com/v3/users/followers/#check-if-you-are-following-a-user>

=cut

sub Ghojo::AuthenticatedUser::you_are_following ( $self ) {
	my $collection = $self->get_paged_resources(
		endpoint   => '/user/following',
		bless_into => 'Ghojo::Data::UserRecord',
		);
	}

=item * follow_users( USERS )

This is an authenticated API endpoint. This requires the C<user:follow> scope.

L<https://developer.github.com/v3/users/followers/#follow-a-user>

=cut

sub Ghojo::AuthenticatedUser::follow_users ( $self, @users ) {
	my @results;

	foreach my $user ( @users ) {
		push @results, $self->put_single_resource(
			endpoint             => '/user/following/:username',
			endpoint_params      => {username => $user},
			requires_scope       => [ qw(user:follow) ],
			expected_http_status => 204,
			);
		}

	Mojo::Collection->new( @results );
	}

=item * unfollow_users( USERS )

This is an authenticated API endpoint. This requires the C<user:follow> scope.

L<https://developer.github.com/v3/users/followers/#unfollow-a-user>

=cut

sub Ghojo::AuthenticatedUser::unfollow_users ( $self, @users ) {
	my @results;

	foreach my $user ( @users ) {
		# this returns a bunch of Result objects?
		push @results, $self->delete_single_resource(
			endpoint        => '/user/following/:username',
			endpoint_params => { username => $user },
			requires_scope  => [ qw(user:follow) ],
			);
		}

	Mojo::Collection->new( @results );
	}

=back

=head2 Git SSH Keys

=over 4

=item * get_ssh_keys_for_user

This is a public API endpoint.

L<https://developer.github.com/v3/users/keys/#list-public-keys-for-a-user>

=cut

sub Ghojo::PublicUser::get_ssh_keys_for_user ( $self, $user ) {
	my $collection = $self->get_paged_resources(
		endpoint        => '/user/:username/keys',
		endpoint_params => { username => $user },
		bless_into      => 'Ghojo::Data::SSHKey',
		);
	}

=item * get_ssh_keys

This is an authenticated API endpoint. This requires the C<read:public_key> scope.

L<https://developer.github.com/v3/users/keys/#list-your-public-keys>

=cut

sub Ghojo::AuthenticatedUser::get_ssh_keys ( $self ) {
	my $collection = $self->get_paged_resources(
		endpoint       => '/user/keys',
		requires_scope => [ qw(read:public_key) ],
		bless_into     => 'Ghojo::Data::SSHKey',
		);
	}

=item * get_ssh_keys_by_id( LIST_OF_IDS )

This is an authenticated API endpoint. This requires the C<read:public_key> scope.

L<https://developer.github.com/v3/users/keys/#get-a-single-public-key>

=cut

sub Ghojo::AuthenticatedUser::get_ssh_keys_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, $self->get_single_resource(
			endpoint        => '/user/keys/:id',
			endpoint_params => { id => $id },
			requires_scope  => [ qw(read:public_key) ],
			bless_into      => 'Ghojo::Data::SSHKey',
			);
		}

	Mojo::Collection->new( @results );
	}

=item * create_public_key( TITLE, KEY )


	title (string, required) - a name for the public key
	key   (string, required) - the public key

This is an authenticated API endpoint. This requires the C<write:public_key> scope.

L<https://developer.github.com/v3/users/keys/#create-a-public-key>

=cut

sub Ghojo::AuthenticatedUser::create_public_key ( $self, %args ) {
	$self->post_single_resource(
		endpoint             => '/user/keys',
		expected_http_status => 201,
		requires_scope       => [ qw(write:public_key) ],
		bless_into           => 'Ghojo::Data::SSHKey',
		data                 => \%args,
		);
	}

=item * delete_keys_by_id( LIST_OF_IDS )

This is an authenticated API endpoint. This requires the C<admin:public_key> scope.

L<https://developer.github.com/v3/users/keys/#delete-a-public-key>

=cut

sub Ghojo::AuthenticatedUser::delete_keys_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, $self->delete_single_resource(
			endpoint             => '/user/keys/:id',
			endpoint_params      => { id => $id },
			expected_http_status => 204,
			requires_scope       => [ qw(admin:public_key) ],
			);
		}

	Mojo::Collection->new( @results );
	}

=back

=head2 GPG Keys

=over 4

=item * get_gpg_keys( CALLBACK )

This is an authenticated API endpoint. This requires the C<read:gpg_key> scope.

L<https://developer.github.com/v3/users/gpg_keys/#list-your-gpg-keys>

=cut

sub Ghojo::AuthenticatedUser::get_gpg_keys ( $self, $callback = sub { $_[0] } ) {
	my $collection = $self->get_paged_resources(
		endpoint       => '/user/gpg_keys',
		requires_scope => [ qw(read:public_key) ],
		bless_into     => 'Ghojo::Data::GPGKey',
		);
	}

=item * get_gpg_keys_by_id

This is an authenticated API endpoint. This requires the C<read:gpg_key> scope.

L<https://developer.github.com/v3/users/gpg_keys/#get-a-single-gpg-key>

=cut

sub Ghojo::AuthenticatedUser::get_gpg_key_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, $self->get_single_resource(
			endpoint        => '/user/gpg_keys/:id',
			endpoint_params => { id => $id },
			requires_scope  => [ qw(read:public_key) ],
			bless_into      => 'Ghojo::Data::GPGKey',
			);
		}

	Mojo::Collection->new( @results );
	}

=item * add_gpg_keys

This is an authenticated API endpoint. This requires the C<write:gpg_key> scope.

L<https://developer.github.com/v3/users/gpg_keys/#create-a-gpg-key>

=cut

sub Ghojo::AuthenticatedUser::add_gpg_keys ( $self, @keys ) {
	my @results;

	foreach my $key ( @keys ) {
		unless( 0 and Ghojo::Types->is_gpg_key( $key ) ) {
			$self->logger->error( "Key [$key] did not look like a GPG key" );
			push @results, 'Was not a GPG key';
			next;
			}

		my $data = { armored_public_key => $key };

		push @results, $self->post_single_resource(
			endpoint       => '/user/gpg_keys',
			requires_scope => [ qw(write:gpg_key) ],
			data           => $data,
			bless_into     => 'Ghojo::Data::GPGKey',
			);
		}

	Mojo::Collection->new( @results );
	}

=item * delete_gpg_keys_by_id

This is an authenticated API endpoint. This requires the C<write:gpg_key> scope.

L<https://developer.github.com/v3/users/gpg_keys/#delete-a-gpg-key>

=cut

sub Ghojo::AuthenticatedUser::delete_gpg_keys_by_id ( $self, @ids ) {
	my @results;

	foreach my $id ( @ids ) {
		push @results, $self->delete_single_resource(
			endpoint        => '/user/gpg_keys/:id',
			endpoint_params => { id => $id },
			requires_scope  => [ qw(write:gpg_key) ],
			);
		}

	Mojo::Collection->new( @results );
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
