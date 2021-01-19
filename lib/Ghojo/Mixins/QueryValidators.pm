use v5.26;
use experimental qw(signatures);

use Exporter qw(import);
our @EXPORT = qw(
	basic_string boolean
	github_name repo_name
	url
	);

=encoding utf8

=head1 NAME

Ghojo::Mixins::QueryValidators - mixins for some routines to validate API input

=head1 SYNOPSIS

	use Ghojo::Mixins::Validators;

	sub do_something ( ... ) {
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

		$self->post_single_resource(
			endpoint        => '/user/repos',
			query_profile   => $query_profile,
			query_params    => $args,
			json            => $args,
			);
		}

=head1 DESCRIPTION

These are mixins for two methods: C<is_success> and C<is_error>. In
many cases you probably want to provide your own versions of this, but
in this many other cases these are exactly what you want.

=over 4

=item * basic_string( STRING )

Returns true if the argument is a valid string. So far that allows
letters, underscores, digits, horizontal whitespace, and the hyphen.

=cut

sub basic_string { $_[0] =~ m/\A[_A-Z0-9\h-]+\z/ }

=item * boolean( STRING )

Returns true if the input is either one or zero.

=cut

sub boolean { return unless $_[0] =~ m/\A[01]\z/ }

=item * github_name( STRING )

Returns true if the argument is a valid Github account name.

=cut

sub github_name { $_[0] =~ m/\A\S+\z/ }

=item * repo_name( STRING )

Returns true if the argument is a valid Github repository name.

=cut

sub repo_name { $_[0] =~ m/\A\S+\z/ }

=item * url( STRING )

Returns true if the input looks like a URL

=cut

sub url   { 0 }

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
