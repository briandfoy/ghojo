use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Data::File;
use parent qw(Ghojo::Data);

=encoding utf8

=head1 NAME

Ghojo::Data::File - Do the things a file can do

=head1 SYNOPSIS

	use Ghojo::Data;

=head1 DESCRIPTION

=over 4

=item * contents

=cut

use Mojo::Util qw(b64_decode);
sub contents ( $self ) {
	b64_decode( $self->{content} );
	}

sub AUTOLOAD  ( $self ) {
	my $method = our $AUTOLOAD =~ s/.*:://r;
	unless( exists $self->{$method} ) {
		carp "Unknown method $method\n"
		}
	$self->{$method};
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2017, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__

__END__

{
  "type": "file",
  "encoding": "base64",
  "size": 5362,
  "name": "README.md",
  "path": "README.md",
  "content": "encoded content ...",
  "sha": "3d21ec53a331a6f037a91c368710b99387d012c1",
  "url": "https://api.github.com/repos/octokit/octokit.rb/contents/README.md",
  "git_url": "https://api.github.com/repos/octokit/octokit.rb/git/blobs/3d21ec53a331a6f037a91c368710b99387d012c1",
  "html_url": "https://github.com/octokit/octokit.rb/blob/master/README.md",
  "download_url": "https://raw.githubusercontent.com/octokit/octokit.rb/master/README.md",
  "_links": {
    "git": "https://api.github.com/repos/octokit/octokit.rb/git/blobs/3d21ec53a331a6f037a91c368710b99387d012c1",
    "self": "https://api.github.com/repos/octokit/octokit.rb/contents/README.md",
    "html": "https://github.com/octokit/octokit.rb/blob/master/README.md"
  }
}
