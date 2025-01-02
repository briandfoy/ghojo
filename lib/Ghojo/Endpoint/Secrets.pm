use v5.26;

package Ghojo::Endpoint::Secrets;
use experimental qw(signatures);

our $VERSION = '1.001002';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Secrets - The endpoints that deal with secrets

=head1 SYNOPSIS

	use Ghojo;

	my $ghojo = Ghojo->new( ... );

	my $result = $ghojo->labels( $owner, $repo );
	if( $result->is_success ) {
		my $labels = $result->values;  # A Mojo::Collection object
		}

=head1 DESCRIPTION

This section implements the endpoints that deal with secrets.

=head2 Repository Secrets

=over 4


=back

=head2 Organization Secrets

=over 4

=item *

=cut


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
