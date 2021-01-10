use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Exporter qw(import);
our @EXPORT = qw( is_success is_error );

=encoding utf8

=head1 NAME

Ghojo::Mixins::SuccessError - mixins for some polymorphic shenanigans

=head1 SYNOPSIS

	use Ghojo;

=head1 DESCRIPTION

=cut

sub is_success { 1 }
sub is_error   { 0 }

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
