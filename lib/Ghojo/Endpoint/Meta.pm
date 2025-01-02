use v5.26;

package Ghojo::Endpoint::Meta;
use experimental qw(signatures);

our $VERSION = '1.001002';

use Carp qw(croak);
use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Meta - The endpoints that deal with GitHub API meta stuff

=head1 SYNOPSIS

	use Ghojo;

	my $ghojo = Ghojo->new( ... );

	my $result = $ghojo->labels( $owner, $repo );
	if( $result->is_success ) {
		my $labels = $result->values;  # A Mojo::Collection object
		}

=head1 DESCRIPTION

This section implements the endpoints that deal with labels.

=head2 API Root

All of the methods in this section go through C<api_root>.

=over 4

=cut

=item * api_root()

This returns various a hash of URLs associated with GitHub API services for
the current user. It makes the request once per instance then reuses
that data to feed the rest of the method in this section.

If there is a problem accessing this endpoint, it returns an empty hash
ref.

This is an authenticated endpoint.

=item * current_user_url

=item * current_user_authorizations_html_url

=item * authorizations_url

=item * code_search_url

=item * commit_search_url

=item * emails_url

=item * emojis_url

=item * events_url

=item * feeds_url

=item * followers_url

=item * following_url

=item * gists_url

=item * hub_url

=item * issue_search_url

=item * issues_url

=item * keys_url

=item * label_search_url

=item * notifications_url

=item * organization_url

=item * organization_repositories_url

=item * organization_teams_url

=item * public_gists_url

=item * rate_limit_url

=item * repository_url

=item * repository_search_url

=item * current_user_repositories_url

=item * starred_url

=item * starred_gists_url

=item * topic_search_url

=item * user_url

=item * user_organizations_url

=item * user_repositories_url

=item * user_search_url

=cut

sub Ghojo::AuthenticatedUser::api_root ( $self ) {
	state $Cache = {};
	croak "api_root can only be called on an instance" unless ref $self;
	return $Cache->{"$self"} if defined $Cache->{"$self"};

	unless( defined $Cache->{"$self"} ) {
		my $result = $self->get_single_resource(
			endpoint        => '/',
			);
		if( $result->is_error ) {
			return {};
			}
		else {
			$Cache->{"$self"} = $result->values->first;
			}
		}

	return $Cache->{"$self"};
	}

sub Ghojo::AuthenticatedUser::current_user_url ($self) { $self->api_root->{current_user_url} }
sub Ghojo::AuthenticatedUser::current_user_authorizations_html_url ($self) { $self->api_root->{current_user_authorizations_html_url} }
sub Ghojo::AuthenticatedUser::authorizations_url ($self) { $self->api_root->{authorizations_url} }
sub Ghojo::AuthenticatedUser::code_search_url ($self) { $self->api_root->{code_search_url} }
sub Ghojo::AuthenticatedUser::commit_search_url ($self) { $self->api_root->{commit_search_url} }
sub Ghojo::AuthenticatedUser::emails_url ($self) { $self->api_root->{emails_url} }
sub Ghojo::AuthenticatedUser::emojis_url ($self) { $self->api_root->{emojis_url} }
sub Ghojo::AuthenticatedUser::events_url ($self) { $self->api_root->{events_url} }
sub Ghojo::AuthenticatedUser::feeds_url ($self) { $self->api_root->{feeds_url} }
sub Ghojo::AuthenticatedUser::followers_url ($self) { $self->api_root->{followers_url} }
sub Ghojo::AuthenticatedUser::following_url ($self) { $self->api_root->{following_url} }
sub Ghojo::AuthenticatedUser::gists_url ($self) { $self->api_root->{gists_url} }
sub Ghojo::AuthenticatedUser::hub_url ($self) { $self->api_root->{hub_url} }
sub Ghojo::AuthenticatedUser::issue_search_url ($self) { $self->api_root->{issue_search_url} }
sub Ghojo::AuthenticatedUser::issues_url ($self) { $self->api_root->{issues_url} }
sub Ghojo::AuthenticatedUser::keys_url ($self) { $self->api_root->{keys_url} }
sub Ghojo::AuthenticatedUser::label_search_url ($self) { $self->api_root->{label_search_url} }
sub Ghojo::AuthenticatedUser::notifications_url ($self) { $self->api_root->{notifications_url} }
sub Ghojo::AuthenticatedUser::organization_url ($self) { $self->api_root->{organization_url} }
sub Ghojo::AuthenticatedUser::organization_repositories_url ($self) { $self->api_root->{organization_repositories_url} }
sub Ghojo::AuthenticatedUser::organization_teams_url ($self) { $self->api_root->{organization_teams_url} }
sub Ghojo::AuthenticatedUser::public_gists_url ($self) { $self->api_root->{public_gists_url} }
sub Ghojo::AuthenticatedUser::rate_limit_url ($self) { $self->api_root->{rate_limit_url} }
sub Ghojo::AuthenticatedUser::repository_url ($self) { $self->api_root->{repository_url} }
sub Ghojo::AuthenticatedUser::repository_search_url ($self) { $self->api_root->{repository_search_url} }
sub Ghojo::AuthenticatedUser::current_user_repositories_url ($self) { $self->api_root->{current_user_repositories_url} }
sub Ghojo::AuthenticatedUser::starred_url ($self) { $self->api_root->{starred_url} }
sub Ghojo::AuthenticatedUser::starred_gists_url ($self) { $self->api_root->{starred_gists_url} }
sub Ghojo::AuthenticatedUser::topic_search_url ($self) { $self->api_root->{topic_search_url} }
sub Ghojo::AuthenticatedUser::user_url ($self) { $self->api_root->{user_url} }
sub Ghojo::AuthenticatedUser::user_organizations_url ($self) { $self->api_root->{user_organizations_url} }
sub Ghojo::AuthenticatedUser::user_repositories_url ($self) { $self->api_root->{user_repositories_url} }
sub Ghojo::AuthenticatedUser::user_search_url ($self) { $self->api_root->{user_search_url} }

=back

=head2 Meta

=cut

sub Ghojo::PublicUser::_array_ref_for ($self, $section) {
	my $result = $self->meta;

	my $grand = $result->values->first;

	[ $grand->{$section}->@* ]
	}

sub Ghojo::PublicUser::_hash_ref_for ($self, $section) {
	my $result = $self->meta;

	my $grand = $result->values->first;

	{ $grand->{$section}->%* }
	}

=over 4

=item * actions_addresses

Returns an array reference of IP addresses for the GitHub Actions.

=cut

sub Ghojo::AuthenticatedUser::actions_addresses ($self) {
	$self->_ip_addresses_for('actions');
	}

=item * all_ip_addresses

Return an array reference of all the addresses the GitHub declares
it uses, in CIDR notation.

=cut

sub Ghojo::AuthenticatedUser::all_ip_addresses ($self) {
	my $result = $self->meta;
	my $hash = $result->values->first;

	my %Seen;
	my @addresses =
		grep { ! $Seen{$_}++ }
		map {
			my $method = "${_}_addresses";
			$hash->$method->@*
			} qw(
			actions api dependabot git hook importer packages pages web
			);

	return \@addresses;
	}

=item * api_addresses

Returns an array reference of IP addresses for the GitHub API.

=cut

sub Ghojo::AuthenticatedUser::api_addresses ($self) { $self->_ip_addresses_for('api') }

=item * dependabot_addresses

Returns an array reference of IP addresses for the GitHub Dependabot.

=cut

sub Ghojo::AuthenticatedUser::dependabot_addresses ($self) { $self->_ip_addresses_for('dependabot') }

=item * meta

Returns all of the Meta information hash. These are accesible by the
other methods in this section too.

=cut

sub Ghojo::AuthenticatedUser::meta ($self, $refresh = 0) {
	$self->get_single_resource(
		endpoint   => '/meta',
		);
	}

=item * git_addresses

Returns an array reference of IP addresses for the GitHub Git servers.

=cut

sub Ghojo::AuthenticatedUser::git_addresses ($self) { $self->_array_ref_for('git') }

=item * hook_addresses

Returns an array reference of IP addresses for the GitHub Hooks.

=cut

sub Ghojo::AuthenticatedUser::hook_addresses ($self) { $self->_array_ref_for('hook') }

=item * importer_addresses

Returns an array reference of IP addresses for the GitHub Importer.

=cut

sub Ghojo::AuthenticatedUser::importer_addresses ($self) { $self->_array_ref_for('importer') }

=item * packages_addresses

Returns an array reference of IP addresses for the GitHub Packages.

=cut

sub Ghojo::AuthenticatedUser::packages_addresses ($self) { $self->_array_ref_for('packages') }

=item * pages_addresses

Returns an array reference of IP addresses for the GitHub Pages.

=cut

sub Ghojo::AuthenticatedUser::pages_addresses    ($self) { $self->_array_ref_for('pages') }

=item * ssh_keys

Returns an array reference of the ssh keys for GitHub.

=cut

sub Ghojo::AuthenticatedUser::ssh_keys ($self)  { $self->_array_ref_for('ssh_keys') }

=item * ssh_key_fingerprints

Returns a hash reference of the ssh key fingerprints for GitHub.

=cut

sub Ghojo::AuthenticatedUser::ssh_key_fingerprints ($self) { $self->_hash_ref_for('ssh_keys') }

=item * verifiable_password_authentication

Returns true if the API instances allows username / password logins.
That's basically the Enterprise version of GitHub, which Ghojo so far
doesn't support.

=cut

sub Ghojo::AuthenticatedUser::verifiable_password_authentication ($self) {
	my $result = $self->meta;

	$result->values->first->{verifiable_password_authentication};
	}

=item * web_addresses

Returns an array reference of IP addresses for the GitHub web servers.

=cut

sub Ghojo::AuthenticatedUser::web_addresses ($self) { $self->_array_ref_for('web') }

=back

=head2 Octocat

=over 4

=item * octocat

=cut

sub Ghojo::AuthenticatedUser::octocat ( $self ) {
	$self->get_single_resource(
		endpoint    => '/octocat',
		bless_into  => 'Ghojo::Data::String',
		raw_content => 1,
		);
	}

=back

=head2 API version

=over 4

=item * api_versions

Returns an array ref of API versions.


=cut

sub Ghojo::AuthenticatedUser::api_versions ( $self ) {
	my $result = $self->get_single_resource(
		endpoint   => '/api_versions',
		);

	[ $result->values->first->@* ]
	}

=back

=head2 Zen of GitHub

=over 4

=item * zen

Returns a string from the Zen of GitHub.

See https://ben.balter.com/2015/08/12/the-zen-of-github/

=cut

sub Ghojo::AuthenticatedUser::zen ( $self ) {
	$self->get_single_resource(
		endpoint    => '/zen',
		bless_into  => 'Ghojo::Data::String',
		raw_content => 1,
		);
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2024, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
