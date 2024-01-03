use v5.26;
use experimental qw(signatures);

use Exporter qw(import);
our @EXPORT = qw( is_success is_error );

=encoding utf8

=head1 NAME

Ghojo::Mixins::SuccessError - mixins for some polymorphic shenanigans

=head1 SYNOPSIS

	use Ghojo;

=head1 DESCRIPTION

These are mixins for two methods: C<is_success> and C<is_error>. In
many cases you probably want to provide your own versions of this, but
in this many other cases these are exactly what you want.

=over 4

=item * is_success

Returns 1

=cut

sub is_success { 1 }

=item * is_error

Returns 0

=cut

sub is_error   { 0 }

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
