use v5.24.0;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Endpoint::Miscellaneous;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

use Mojo::Util qw(b64_decode);

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Miscellaneous - endpoints with no other place to be

=head1 SYNOPSIS

	use Ghojo;

=head1 DESCRIPTION

	* Miscellaneous ( Ghojo/Miscellaneous.pm )
		* Emojis
		* Gitignore
		* Licenses
		* Markdown
		* Meta
		* Rate Limit

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
		endpoint => '/emojis',
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

Github has a repository of F<gitignore> templates for several
languages. One endpoint returns the list of names and another returns
the content.

You probably only need to ask for the name or the content you want.
They will call the right things to fetch the list of names or grab
the content for you. It also caches it so you don't spend your rate
limit doing this over and over again.

	my $result = $ghojo->get_gitignore_template( 'Perl' );
	if( $result->is_success ) {
		say "Is this from the cache? " . $result->extras->cache_hit ? 'Yes' : 'No';
		say "Template is:\n" . $result->values->first->{source};
		}

To get the raw template source, you can skip most of this:

	my $source = $ghojo->get_raw_gitignore_template( 'Perl' );

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
		endpoint   => '/gitignore/templates',
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
		endpoint        => '/gitignore/templates/:template',
		endpoint_params => { template => $template },
		bless_into      => 'Ghojo::Data::Gitignore', # XXX This is not sufficient
		);

	return $result if $result->is_error;

	# store the result as the value in the cache. This is the hash ref
	# that represents the JSON response. Otherwise, the value should
	# be undef.
	$self->gitignore_template_cache->{$template} = $result->values->first;
	$result->add_extras( cache_hit => 0 );

	$result;
	}

=item * get_raw_gitignore_template( NAME )

Get the raw content for the named template. This is the C<source> value
you see in C<get_gitignore_template>. This is actually a wrapper around
C<get_gitignore_template> that translates that result for you. It returns
a result object if there's a failure, but otherwise returns the raw
template data:

	my $result = $ghojo->get_raw_gitignore_template( 'Perl' );
	if( ref $result ) { # an error
		...;
		}
	else { # must be a scalar
		say "Source is\n$result";
		}

This is a public API endpoint.

L<https://developer.github.com/v3/gitignore/#get-a-single-template>

=cut

sub Ghojo::PublicUser::get_raw_gitignore_template ( $self, $template ) {
	my $result = $self->get_single_resource(
		endpoint        => '/gitignore/templates/:template',
		endpoint_params => { template => $template },
		bless_into      => 'Ghojo::Data::Gitignore', # XXX This is not sufficient (why not?)
		);

	return $result if $result->is_error;

	$result->values->first->{source};
	}

}

=back

=head2 Licenses

=over 4

=item * get_licenses

Fetch the list of licenses from GitHub. This returns a C<Ghojo::Result>
object. The value is an array reference of C<Ghojo::Data::License>
objects.

This is a public API endpoint.

L<https://developer.github.com/v3/licenses/#list-all-licenses>

Needs to have the MIME type C<application/vnd.github.drax-preview+json>
as the only type in the C<Accept> header.

=cut

BEGIN {
my $cache = {};

sub Ghojo::PublicUser::get_license_names ( $self ) {
	$self->entered_sub;

	return Ghojo::Result->success({
		values => [ $self->license_names_from_cache ],
		extras => {
			cache_hit => 1,
			}
		}) if keys $cache->%*;

	my $result = $self->get_single_resource(
		endpoint => '/licenses',
		accepts  => 'application/vnd.github.drax-preview+json',
		);

	return $result if $result->is_error;

	# this is odd because we have multiple values in the response
	# but that's mostly a paged response
	my $array = $result->values->first;
	bless $_, 'Ghojo::Data::License' for $array->@*;

	my %hash = map {
		$_->{key} => {
			id => $_,
			content => undef
			}
		} $array->@*;

	$self->set_license_cache( \%hash );
	$result->add_extras( cache_hit => 0 );

	$result;
	}

=item * set_license_cache( HASH_REF )

=cut

sub Ghojo::PublicUser::set_license_cache ( $self, $hash ) {
	$cache = $hash
	}

=item * license_names_from_cache

Return an array reference of the license names in the cache.

=cut

sub Ghojo::PublicUser::license_names_from_cache ( $self ) {
	[ keys $self->license_cache->%* ]
	}

=item * license_cache

Return the license cache. It's a hash with the id of the license
type as the key and second-level hash as the value. It looks like this:

	{
	'mit' => {
		id =>  {
			"key": "mit",
			"name": "MIT License",
			"spdx_id": "MIT",
			"url": "https://api.github.com/licenses/mit",
			"featured": true,
			},
		content => '...',
		},
	}

=cut

sub Ghojo::PublicUser::license_cache ( $self ) {
	return $cache if keys $cache->%*;

	$self->get_license_names;
	}

=item * license_exists( LICENSE )

Returns true of the license name exists, and false otherwise. This
looks in the local license cache, which might contact GitHub to get
data.

The license list is very short. It's probably:

	apache-2.0
	mit
	epl-1.0
	gpl-2.0
	lgpl-2.1
	unlicense
	mpl-2.0
	bsd-3-clause
	bsd-2-clause
	lgpl-3.0
	agpl-3.0
	gpl-3.0

See the blog post "Open source license usage on GitHub.com"
L<https://github.com/blog/1964-open-source-license-usage-on-github-com>

=cut

# XXX: find some things that are close?
sub Ghojo::PublicUser::license_exists ( $self, $license ) {
	exists $self->license_cache->{ $license }
	}

=item * get_license

Get an individual license

This is a public API endpoint.

L<https://developer.github.com/v3/licenses/#get-an-individual-license>

=cut

sub Ghojo::PublicUser::get_license_content ( $self, $license ) {
	return Ghojo::Result->error({
		message => "License ($license) does not exist",
		}) unless $self->license_exists( $license );

	my $result = $self->get_single_resource(
		endpoint        => '/licenses/:license',
		endpoint_params => { license => $license },
		bless_into      => 'Ghojo::Data::LicenseContent',
		accepts         => 'application/vnd.github.drax-preview+json',
		);
	}

=item * get_license_for_repo( OWNER, REPO )

Get a repository's license

This is a public API endpoint.

L<https://developer.github.com/v3/licenses/#get-a-repositorys-license>

=cut

sub Ghojo::PublicUser::get_license_name_for_repo ( $self, $owner, $repo ) {
	my $result = $self->get_single_resource(
		endpoint        => '/repos/:owner/:repo',
		endpoint_params => { owner => $owner, repo => $repo },
		bless_into      => 'Ghojo::Data::License',
		accepts         => 'application/vnd.github.drax-preview+json',
		);
	}

=item * get_license_content_for_repo( OWNER, REPO )

Get the contents of a repository's license	GET	/repos/:owner/:repo/license

This is a public API endpoint.

L<https://developer.github.com/v3/licenses/#get-the-contents-of-a-repositorys-license>

=cut

sub Ghojo::PublicUser::get_license_content_for_repo ( $self, $owner, $repo ) {
	my $result = $self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/license',
		endpoint_params => { owner => $owner, repo => $repo },
		bless_into      => 'Ghojo::Data::LicenseContent',
		accepts         => 'application/vnd.github.drax-preview+json',
		);
	}

}

=back

=head2 Markdown

=over 4

=item * render_markdown( MARKDOWN_SCALAR [, REPO ] )

Render an arbitrary Markdown document HTML. If you supply the optional
REPO argument, it knows how to translate some text referring to the
repo as links (such as C<github/linguist#1> into an issues link).

The code GitHub uses to render markdown: L<https://github.com/github/markup>

This is a public API endpoint.

L<https://developer.github.com/v3/markdown/#render-an-arbitrary-markdown-document>

=cut

sub Ghojo::PublicUser::render_markdown ( $self, $markdown, $repo = undef ) {
	state $profile = {
		params => {
			text    => sub { length $_[0] },
			mode    => [ qw(markdown gfm) ],
			context => qr|\A \S+ / \S+ \z|x, # a repo context, only matters for gfm
			},
		required => [ qw(text) ]
		};

	my $args = {};
	$args->{text} = $markdown;

	# XXX: check that repo exists
	if( defined $repo ) {
		$args->{mode}    = 'gfm';
		$args->{context} = $repo;
		push @{ $profile->{required} }, 'context';
		}
	$args->{mode} //= 'markdown';

	my $result = $self->validate_profile( $args, $profile );
	return $result if $result->is_error;

	my $result = $self->post_single_resource(
		endpoint             => '/markdown',
		expected_http_status => 200,
		raw_content          => 1,
		json                 => $args,
		);
	}

=item * render_raw_markdown

Render a Markdown document in raw mode. This doesn't include the special
GitHub links to repos, issues, and the like.

This is a public API endpoint.

L<https://developer.github.com/v3/markdown/#render-a-markdown-document-in-raw-mode>

=cut

# takes text/plain or text/x-markdown
sub Ghojo::PublicUser::render_raw_markdown ( $self, $markdown ) {
	$self->post_single_resource(
		endpoint             => '/markdown/raw',
		expected_http_status => 200,
		content_type         => 'text/x-markdown',
		raw_content          => 1,
		body                 => $markdown,
		);
	}

=back

=head2 GitHub meta information

=over 4

=item * get_github_info

Information about GitHub.com, mostly about IP addresses and the SHA
for the services.

This is a public API endpoint.

L<https://developer.github.com/v3/meta/>

=cut

sub Ghojo::PublicUser::get_github_info ( $self ) {
	$self->get_single_resource(
		endpoint   => '/meta',
		bless_into => 'Ghojo::Data::Meta',
		);
	}

=back

=head2 Rate limit

=over 4

=item * get_rate_limit

Get your current rate limit status. If there's an error, it returns
a L<Ghojo::Result> object. Otherwise, it returns a C<Ghojo::Data::Rate>
object. That's a hash that looks something like:

	{
	  "resources": {
		"core": {
		  "limit": 5000,
		  "remaining": 4999,
		  "reset": 1372700873
		},
		"search": {
		  "limit": 30,
		  "remaining": 18,
		  "reset": 1372697452
		}
	  },
	}

This removes the C<rate> key that is deprecated.

Although this endpoint does not count against your limit, there's a cache
time of 60 seconds (or whatever C<rate_limit_cache_time> returns). This
is just to be nice to the network.

This is a public API endpoint.

L<https://developer.github.com/v3/rate_limit/>

=cut


BEGIN {
	my $cache = [];
	package Ghojo;
	sub rate_limit_cache_time { 60 }
	sub set_rate_limit_cache   ( $self, $data ) { $cache = [ $data, time ] }
	sub get_rate_limit_cache   ( $self )        { $cache }
	sub clear_rate_limit_cache ( $self )        { $cache = [] }
	sub rate_limit_cache_is_fresh ( $self )    {
		defined $cache->[0]
			and
		time - $cache->[0] <= $self->rate_limit_cache_time
		}
	}

sub Ghojo::PublicUser::get_rate_limit ( $self ) {
	my $cache = $self->get_rate_limit_cache;
	return $cache->[0] if $self->rate_limit_cache_is_fresh;

	my $result = $self->get_single_resource(
		endpoint => '/rate_limit',
		bless_into => 'Ghojo::Data::Rate',
		);

	return $result if $result->is_error;

	delete $result->{rate};

	$self->set_rate_limit_cache( $result );

	$cache->[0];
	}

# XXX: Should this be somewhere else?
sub Ghojo::PublicUser::is_public_api_rate_limit ( $self ) { $self->core_rate_limit < 100 }

sub Ghojo::PublicUser::is_authenticated_api_rate_limit ( $self ) { $self->core_rate_limit == 5000 }

sub Ghojo::PublicUser::core_rate_limit ( $self ) {
	$self->get_rate_limit->{resources}{core}{limit};
	}

sub Ghojo::PublicUser::core_rate_limit_left ( $self ) {
	$self->get_rate_limit->{resources}{core}{remaining};
	}

sub Ghojo::PublicUser::core_rate_limit_percent_left ( $self ) {
	sprintf "%d",
		100
			*
		( $self->core_rate_limit - $self->core_rate_limit_left )
			/ #/
		$self->core_rate_limit;
	}

sub Ghojo::PublicUser::seconds_until_core_rate_limit_reset ( $self ) {
	$self->get_rate_limit->{resources}{core}{reset} - time
	}

sub Ghojo::PublicUser::search_rate_limit ( $self ) {
	$self->get_rate_limit->{resources}{search}{limit};
	}

sub Ghojo::PublicUser::search_rate_limit_left ( $self ) {
	$self->get_rate_limit->{resources}{search}{remaining};
	}

sub Ghojo::PublicUser::search_rate_limit_percent_left ( $self ) {
	sprintf "%d",
		100
			*
		( $self->search_rate_limit - $self->search_rate_limit_left )
			/ #/
		$self->search_rate_limit;
	}

sub Ghojo::PublicUser::seconds_until_search_rate_limit_reset ( $self ) {
	$self->get_rate_limit->{resources}{search}{reset} - time
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
