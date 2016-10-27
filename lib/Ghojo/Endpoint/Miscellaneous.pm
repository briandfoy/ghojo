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

GitHub's emoji docs: L<https://github.com/showcases/emoji>

There's an emoji code cheatsheet: L<http://www.webpagefx.com/tools/emoji-cheat-sheet/>

=over 4

=item * get_emojis

Get the hash mapping emoji codes (e.g. C<:mailbox_with_no_mail:>) to
the images that GitHub uses to display them.

After fetching the list, this method caches them. If the cache exists,
it returns that instead. The return value is a C<Ghojo::Result> object
that includes the hash. In the C<extras> section, there is a C<cache_hit>
key:

	my $result = $ghojo->get_emojis;
	if( $result->is_success ) {
		say "Is this from the cache? " . $result->extras->{cache_hit} ? 'Yes' : 'No';
		say "Image for :bulb: is " . $result->values->first->{bulb};
		}

You don't have to look in the value returned in C<$result>. Since C<get_emojis>
caches the response, you can call another emojis method without another
API call:

	my $result = $ghojo->get_emojis;
	if( $result->is_success ) {
		say "Is this from the cache? " . $result->extras->{cache_hit} ? 'Yes' : 'No';
		say "Image for :bulb: is " . $ghojo->get_emoji_image_for( ':bulb:' );
		}

This is a public API endpoint.

L<https://developer.github.com/v3/emojis/>

=cut

BEGIN {
my $cache = {};

sub Ghojo::PublicUser::get_emojis ( $self ) {
	$self->entered_sub;

	return Ghojo::Result->success({
		values => [ $self->emoji_cache ],
		extras => {
			cache_hit => 1,
			}
		}) if keys $cache->%*;

	my $result = $self->get_single_resource(
		$self->endpoint_to_url( '/emojis' ),
		bless_into => 'Ghojo::Data::Emojis',
		);

	return $result if $result->is_error;

	my $hash = $result->values->first;
	$self->set_emoji_cache( $hash );
	$result->add_extras( cache_hit => 0 );

	$result;
	}


=item * set_emoji_cache( HASHREF )

Save the hash that maps the emoji code to the GitHub image URL.

=cut

sub Ghojo::PublicUser::set_emoji_cache ( $self, $hash ) {
	$self->entered_sub;
	$cache = $hash;
	}

=item * emoji_cache()

Return the hash reference that is the emoji cache. If the cache
is empty, it fetches the emojis.

=cut

sub Ghojo::PublicUser::emoji_cache ( $self ) {
	$self->entered_sub;
	$self->get_emojis unless keys $cache->%*;
	$cache;
	}

=item * clear_emoji_cache()

Forget that you ever saw Emojis. Oh, if it were this simple.

=cut

sub Ghojo::PublicUser::clear_emoji_cache ( $self ) {
	$self->entered_sub;
	$cache = {};
	}

=item * get_emoji_image_for_code( EMOJI_CODE )

Return the path for the image for the EMOJI_CODE. This can be
with or without the colons around the code:

	$ghojo->get_emoji_image_for_code( ':smile_cat:' );

	# or without colons
	$ghojo->get_emoji_image_for_code( 'smile_cat' );

If there is no recognized emoji code, this returns nothing.

In the unlikely chance that GitHub updates the emoji codes while the
program is still running, you can use C<clear_emoji_hash> to start
over.

=cut

sub Ghojo::PublicUser::get_emoji_image_for( $self, $emoji_code ) {
	$self->entered_sub;

	my $emoji = lc $emoji_code;
	$emoji =~ s/\A:|:\z//g;

	if( exists $self->emoji_cache->{$emoji} ) {
		$self->emoji_cache->{$emoji}
		}
	else {
		$self->logger->warn( "There's no image for emoji code $emoji" );
		return;
		}

	}

=item * get_emoji_char_for( EMOJI_CODE )

Return the character for EMOJI_CODE. If there is no such EMOJI_CODE,
this returns nothing.

=cut

sub Ghojo::PublicUser::get_emoji_char_for( $self, $emoji_code ) {
	$self->entered_sub;

	my $image = $self->get_emoji_image_for( $emoji_code );
	return unless $image;

	my( $hex_code ) = $image =~ m|/([0-9a-f]+)\.png\?v\d+\z|;
	$self->logger->debug( "Hex for emoji code $emoji_code is $hex_code" );
	my $char = chr hex $hex_code;
	}

}

=back

=head2 Gitignore templates

=over 4

=item * get_gitignore_template_names

List the available gitignore templates for various languages stored
in the github/gitignore repo: L<https://github.com/github/gitignore>.

This is a public API endpoint.

L<https://developer.github.com/v3/gitignore/>

=cut

BEGIN {
my $cache = {};

sub Ghojo::PublicUser::get_gitignore_template_names ( $self ) {
	$self->entered_sub;

	return Ghojo::Result->success({
		values => [ $self->gitignore_template_cache ],
		extras => {
			cache_hit => 1,
			}
		}) if keys $cache->%*;

	my $result = $self->get_single_resource(
		$self->endpoint_to_url( '/gitignore/templates' ),
		bless_into => 'Ghojo::Data::Gitignore',
		);

	return $result if $result->is_error;

	my $array = $result->values->first;
	my %hash = map { $_ => undef } $array->@*;

	$self->set_gitignore_template_cache( \%hash );
	$result->add_extras( cache_hit => 0 );

	$result;
	}

=item * set_gitignore_template_cache( HASHREF )

Save the hash that maps the gitignore template name to the template content.

=cut

sub Ghojo::PublicUser::set_gitignore_template_cache ( $self, $hash ) {
	$self->entered_sub;
	$cache = $hash;
	}

=item * gitignore_template_cache()

Return the hash reference that is the gitignore template cache. If the cache
is empty, it fetches the template names.

If there's nothing in the cache, this fetches the list for you. This means
that you don't have to fetch the list explicitly.

=cut

sub Ghojo::PublicUser::gitignore_template_cache ( $self ) {
	$self->entered_sub;
	$self->get_gitignore_template_names unless keys $cache->%*;
	$cache;
	}

=item * clear_gitignore_template_cache()

Forget that you ever saw gitignore template name list.

=cut

sub Ghojo::PublicUser::clear_gitignore_template_cache ( $self ) {
	$self->entered_sub;
	$cache = {};
	}

=item * gitignore_template_name_exists( NAME )

Returns true if the NAME is an available template. Returns nothing
otherwise. This will look in the cache, which will fetch the list of
names if the cache is empty.

GitHub's documentation about ignoring files: L<https://help.github.com/articles/ignoring-files/>

The repo of gitignore templates: L<https://github.com/github/gitignore>

=cut

sub Ghojo::PublicUser::gitignore_template_name_exists ( $self, $name ) {
	exists $self->gitignore_template_cache->{$name};
	}

=item * get_gitignore_template( NAME )

Get the content for the named template. If the named template does
not exist, returns nothing. For this call,

	my $result = $ghojo->get_gitignore_template( 'Perl' );
	if( $result->is_success ) {
		my $name = $result->values->first->{name}; # should be same as arg
		my $data = $result->values->first->{source};
		}

This is a public API endpoint.

L<https://developer.github.com/v3/gitignore/#get-a-single-template>

=cut

sub Ghojo::PublicUser::get_gitignore_template ( $self, $template ) {
	$self->entered_sub;

	if( defined $self->gitignore_template_cache->{$template} ) {
		$self->logger->debug( "gitignore template is cached" );
		return Ghojo::Result->success({
			values => [ $self->gitignore_template_cache->{$template} ],
			extras => {
				cache_hit => 1,
				}
			});
		}

	my $result = $self->get_single_resource(
		$self->endpoint_to_url( '/gitignore/templates/:template', { template => $template } ),
		bless_into => 'Ghojo::Data::Gitignore', # XXX This is not sufficient
		);

	return $result if $result->is_error;

	# store the result as the value in the cache. This is the hash ref
	# that represents the JSON response. Otherwise, the value should
	# be undef.
	$self->gitignore_template_cache->{$template} = $result->values->first;
	$result->add_extras( cache_hit => 0 );

	$result;
	}

=item * get_gitignore_template( NAME )

Get the raw content for the named template. This is the C<source> value
you see in C<get_gitignore_template>. This is actually a wrapper around
C<get_gitignore_template> that translates that result for you.

This is a public API endpoint.

L<https://developer.github.com/v3/gitignore/#get-a-single-template>

=cut

sub Ghojo::PublicUser::get_raw_gitignore_template ( $self, $template ) {
	my $result = $self->get_single_resource(
		$self->endpoint_to_url( '/gitignore/templates/:template', { template => $template } ),
		bless_into => 'Ghojo::Data::Gitignore', # XXX This is not sufficient
		);

	return $result if $result->is_error;

	$result->values->first->{source};
	}

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

Information about GitHub.com, mostly about IP addresses and the SHA
for the services.

This is a public API endpoint.

L<>

=cut

sub Ghojo::PublicUser::get_github_info ( $self ) {
	$self->get_single_resource(
		$self->endpoint_to_url( '/meta' ),
		bless_into => 'Ghojo::Data::Meta',
		);
	}

=back

=head2 Rate limit

=over 4

=item * rate_limit

Get your current rate limit status	GET	/rate_limit

This is a public API endpoint.

L<https://developer.github.com/v3/meta/>

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
