use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Endpoint::PullRequests;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::PullRequests - The endpoints that deal with pull requests

=head1 SYNOPSIS


=head1 DESCRIPTION

	Reactions
		Commit Comment
		Issue
		Issue Comment
		Pull Request Review Comment

=head2  Commit comment

=over 4

=item *

=back

=head2  Issue

=over 4

=item *

=back

=head2  Issue comment

=over 4

=item *

=back

=head2  Pull request review comment

=over 4

=item *

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
