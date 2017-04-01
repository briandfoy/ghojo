use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Endpoint::Contents;

our $VERSION = '1.001001';

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

=item *

=cut

# GET /repos/:owner/:repo/readme
sub Ghojo::PublicUser::get_readme ( $self, $owner, $repo ) {
	my $result = $self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/readme',
		endpoint_params => { owner => $owner, repo => $repo },
		bless_into      => 'Ghojo::Data::File',
		);
	}

# GET /repos/:owner/:repo/contents/:path
# file
# directory
# symlink

# what happens if the file doesn't exist?
sub Ghojo::PublicUser::get_contents ( $self, $owner, $repo, $path ) {
	$self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/contents/:path',
		endpoint_params => { owner => $owner, repo => $repo, path => $path },
		bless_into      => 'Ghojo::Data::File',
		);
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

sub Ghojo::AuthenticatedUser::create_file () {
	}

sub Ghojo::AuthenticatedUser::update_file () {
	}

=item *

DELETE /repos/:owner/:repo/contents/:path
path	string	Required. The content path.
message	string	Required. The commit message.
sha	string	Required. The blob SHA of the file being replaced.
branch	string	The branch name. Default: the repository’s default branch (usually master)

=cut

sub Ghojo::AuthenticatedUser::delete_file () {

	}

=item *

GET /repos/:owner/:repo/:archive_format/:ref

archive_format	string	Can be either tarball or zipball. Default: tarball
ref	string	A valid Git reference. Default: the repository’s default branch (usually master)


=cut

sub Ghojo::AuthenticatedUser::get_archive_link () {
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
