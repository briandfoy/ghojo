use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Data;
use parent qw( Hash::AsObject ); # as a quick fix. I'd rather lose the dependency

use Ghojo::Mixins::SuccessError;

# until we need to build out these classes
my @classes = qw( SSHKey GPGKey UserRecord Email Grant Repo );
foreach my $class ( @classes ) {
	no strict 'refs';
	@{ "Ghojo::Data::$class\::ISA" } = __PACKAGE__;
	}

__PACKAGE__

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
