use v5.26;
use experimental qw(signatures);

package Ghojo::Endpoint::Contents;

our $VERSION = '1.001001';

use Ghojo::Constants;
use Ghojo::Data; # All sorts of basic types

use Mojo::Collection;
use Mojo::URL;
use Mojo::Util qw(b64_decode);

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Contents - The endpoints that deal with gists

=head1 SYNOPSIS


=head1 DESCRIPTION

	Repositories
		Contents

=head2  General object thingys

=over 4

=item * get_readme( $owner, $repo, $args = HASH_REF )

Get the contents of the readme file. If the third argument,
C<$as_html>, is true, the result is the HTML-ized version from the
GitHub translators. GitHub determines what file represents the readme
file. It might be F<README>, F<README.md>, F<README.pod>, or something
else.

The args hash ref:

	as_html - return the GitHub HTML version if true (raw contents otherwise)

=cut

sub Ghojo::PublicUser::get_readme ( $self, $owner, $repo, $args = {} ) {
	state $profile = {
		params => {
			'ref'   => qr/\A \S+ \z/x,
			},
		required => [],
		};

	my $accepts_type_method = 'version_' . ( $args->{as_html} ? 'html' : 'raw' );
	my $class =  'Ghojo::Data::Content::' .
		( $args->{as_html} ? 'HTML' : 'Raw' );

	delete $args->{as_html};

	$args->{'ref'} = 'master' unless defined $args->{'ref'};

	my $result = $self->validate_profile( $args, $profile );
	return $result if $result->is_error;

	$result = $self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/readme',
		endpoint_params => { owner => $owner, repo => $repo },
		accepts         => $self->$accepts_type_method(),
		raw_content     => 1,
		json            => $args,
		);

	$class->new( $result->single_value );
	}

=item * get_readme_raw( $owner, $repo, $args )

Get the raw contents of the readme file.

=cut

sub Ghojo::PublicUser::get_readme_raw ( $self, $owner, $repo, $args = {} ) {
	$args->{as_html} = 0;
	$self->get_readme( $owner, $repo, $args );
	}

=item * get_readme_html( $owner, $repo, $args )

Get the HTML contents of the README file. This uses the internal HTML
formatters in GitHub to translate the readme file.

=cut

sub Ghojo::PublicUser::get_readme_html ( $self, $owner, $repo, $args = {} ) {
	$args->{as_html} = 1;
	$self->get_readme( $owner, $repo, $args );
	}

=item * get_contents( $owner, $repo $path, $args )

The args hash ref:

	ref - a ref for the file (a branch, commit, or tag). Default is "master".


# GET /repos/:owner/:repo/contents/:path
	# file - hash
	# directory - array
	# symlink - hash

# what happens if the file doesn't exist?

=cut

sub Ghojo::PublicUser::get_contents ( $self, $owner, $repo, $path, $args = {} ) {
	state $profile = {
		params => {
			'ref'   => qr/\A \S+ \z/x,
			},
		required => [],
		};

	$args->{'ref'} = 'master' unless defined $args->{'ref'};

	my $result = $self->validate_profile( $args, $profile );
	return $result if $result->is_error;

	$result = $self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/contents/:path',
		endpoint_params => { owner => $owner, repo => $repo, path => $path },
		json            => $args,
		);

	return $result unless $result->is_success;

	my $content = $result->single_value;

	state $types_to_classes = {
		'file'      => 'Ghojo::Data::Content::File',
		'symlink'   => 'Ghojo::Data::Content::Symlink',
		'submodule' => 'Ghojo::Data::Content::Submodule',
		'dir'       => 'Ghojo::Data::Content::Directory',
		'default'   => 'Ghojo::Data::Content::Unknown',
		};

	if( ref $content eq ref {} ) {    # file, symlink, submodule
		my $type = $types_to_classes->{ $content->{type} } //
			$types_to_classes->{ 'default' };
		unless( eval "require $type; 1" ) {
			my $message = "Could not load $type: $@";
			$self->logger->error( $message );
			my $error_result = Ghojo::Result->error( {
				values       => [ ],
				description  => "Failed to type a content module",
				message      => $message,
				error_code   => MODULE_LOAD_FAILURE,
				extras       => { },
				} );
			return $error_result;
			}
		bless $content, $type;
		}
	elsif( ref $content eq ref [] ) { # directory
		foreach my $c ( $content->@* ) {
			my $type = $types_to_classes->{ $c->{type} } // $types_to_classes->{ 'default' };
			bless $c, $type;
			}
		bless $content, 'Ghojo::Data::Content::DirectoryListing',
		}

	return Ghojo::Result->success( {
		values => [ $content ],
		} );
	}

=item * get_decoded_contents( $owner, $repo, $path, $args )

The args hash ref:

	ref - a ref for the file (a branch, commit, or tag). Default is "master".


# GET /repos/:owner/:repo/contents/:path
	# file - hash
	# directory - array
	# symlink - hash

# what happens if the file doesn't exist?

=cut

sub Ghojo::PublicUser::get_decoded_contents ( $self, $owner, $repo, $path, $args = {} ) {
	my $result = $self->get_contents( $owner, $repo, $path, $args );

	return $result if $result->is_error;

	my $content_obj = $result->single_value;

	if( $content_obj->can( 'decoded_content' ) ) {
		my $decoded = $content_obj->decoded_content;

		return Ghojo::Result->success( {
			values => [ $decoded ],
			} );
		}
	else {
		return Ghojo::Result->error( {
			values  => [ ],
			message => 'Could not decoded content for type ' . ref $content_obj,
			} );
		}
	}
# PUT /repos/:owner/:repo/contents/:path
# path	string	Required. The content path.
# message	string	Required. The commit message.
# content	string	Required. The new file content, Base64 encoded.
# branch	string	The branch name. Default: the repository’s default branch (usually master)

# author
#	name	string	The name of the author (or committer) of the commit
#	email	string	The email of the author (or committer) of the commit

# committer
#	name	string	The name of the author (or committer) of the commit
#	email	string	The email of the author (or committer) of the commit

sub Ghojo::AuthenticatedUser::create_file ( $self ) {
	$self->not_implemented;
	}

sub Ghojo::AuthenticatedUser::update_file ($self ) {
	$self->not_implemented;
	}

=item *

DELETE /repos/:owner/:repo/contents/:path
path	string	Required. The content path.
message	string	Required. The commit message.
sha	string	Required. The blob SHA of the file being replaced.
branch	string	The branch name. Default: the repository’s default branch (usually master)

=cut

sub Ghojo::AuthenticatedUser::delete_file ( $self ) {
	$self->not_implemented;
	}

=item *

GET /repos/:owner/:repo/:archive_format/:ref

archive_format	string	Can be either tarball or zipball. Default: tarball
ref	string	A valid Git reference. Default: the repository’s default branch (usually master)


=cut

sub Ghojo::AuthenticatedUser::get_archive_link ( $self ) {
	$self->not_implemented;
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2021, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
