# This module loads all of the endpoint modules.

use Ghojo::Endpoint::Users;
use Ghojo::Endpoint::Authorizations;
use Ghojo::Endpoint::Issues;
use Ghojo::Endpoint::Labels;
use Ghojo::Endpoint::Repositories;
use Ghojo::Endpoint::Miscellaneous;

=encoding utf8

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
