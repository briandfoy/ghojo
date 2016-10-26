use v5.24.0;
use feature qw(signatures);
no warnings qw(experimental::signatures);

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Miscellaneous - endpoints with no other place to be

=head1 SYNOPSIS

	use Ghojo;

=head1 DESCRIPTION


=head2 Emojis

=over 4

=item * get_emojis

List emojis	GET	/emojis

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_emojis ( $self ) {
	$self->not_implemented
	}

=back

=head2 Gitignore templates

=over 4

=item * get_gitignore_template_names

Listing available templates	GET	/gitignore/templates

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_gitignore_template_names ( $self ) {
	$self->not_implemented
	}

=item * get_gitignore_template

Get a single template	GET	/gitignore/templates/:template

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_gitignore_template ( $self, $template ) {
	$self->not_implemented
	}

=back

=head2 Licenses

=over 4

=item * get_license_names

List all licenses	GET	/licenses

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_license_names ( $self ) {
	$self->not_implemented
	}

=item * get_license_content

Get an individual license	GET	/licenses/:license

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_license_content ( $self, $license ) {
	$self->not_implemented
	}

=item * get_license_for_repo

Get a repository's license	GET	/repos/:owner/:repo

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_license_name_for_repo ( $self, $owner, $repo ) {
	$self->not_implemented
	}

=item * get_license_content_for_repo

Get the contents of a repository's license	GET	/repos/:owner/:repo/license

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_license_content_for_repo ( $self, $owner, $repo ) {
	$self->not_implemented
	}

=back

=head2 Markdown

=over 4

=item * render_markdown

Render an arbitrary Markdown document	POST	/markdown

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::render_markdown ( $self, $markdown ) {
	$self->not_implemented
	}

=item * render_raw_markdown

Render a Markdown document in raw mode	POST	/markdown/raw

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::render_raw_markdown ( $self, $markdown ) {
	$self->not_implemented
	}

=back

=head2 GitHub meta information

=over 4

=item * get_github_info

Information about GitHub.com	GET	/meta

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_github_info ( $self ) {
	$self->not_implemented
	}

=back

=head2 Rate limit

=over 4

=item * rate_limit

Get your current rate limit status	GET	/rate_limit

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::rate_limit ( $self ) {
	$self->not_implemented
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
it under the same terms as Perl itself.

=cut

__PACKAGE__
