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

=item * counting_number

Returns true if the input only has the ASCII digits 0 to 9.

=cut

sub counting_number { return unless $_[0] =~ m/\A\d+\z/a }

=item * github_name( STRING )

Returns true if the argument is a valid Github account name.

=cut

sub github_name { $_[0] =~ m/\A\S+\z/ }

=item * page_number

Returns true if the argument can represent a page number. This
is a counting number 1 or greater. This does not validate that
the query can return that page number, just that the form looks
like a page number.

=cut

sub page_number { return unless $_[0] =~ m/\A\d+\z/a and $_[0] >= 1 }

=item * per_page_number

Returns true if the argument can represent a per page number (results
per page of response). This is a counting number 1 or greater. This
does not validate that the query can return that many results per
page, just that the form looks like a per page number.

=cut

sub per_page_number { return unless $_[0] =~ m/\A\d+\z/a and $_[0] >= 1 }

=item * repo_name( STRING )

Returns true if the argument is a valid Github repository name.

=cut

sub repo_name { $_[0] =~ m/\A\S+\z/ }

=item * url( STRING )

Returns true if the input looks like a URL

=cut

sub url   { 0 }

=back

=head2 Generators

These validators create anonymous subroutines based on the input.
These are methods rather than regular subroutines.

=over 4

=item * counting_number_between( $min, $max, $opts )


=cut

sub counting_number_between ( $self, $min, $max, $opts ) {
	sub { $_[0] >= $min and $_[0] <= $max }
	}

sub counting_number_up_to ( $self, $max, $opts ) {
	$self->counting_number_between( 0, $max )
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
