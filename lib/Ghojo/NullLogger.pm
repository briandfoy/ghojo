use v5.26;

=encoding utf8

=head1 NAME

Ghojo::NullLogger - An object that responds to every method but does nothing

=head1 SYNOPSIS

	use Ghojo::NullLogger;

	my $logger = Ghojo::NullLogger->new;

=head1 DESCRIPTION

This module is here to stand in for L<Log4perl> if it's not installed.
It reponds to every method, does nothing, and returns the original
object.

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

package Ghojo::NullLogger 0.001 {
	use experimental qw(signatures);
	sub new ( $class ) { bless { }, $class }
	sub is_null_logger ( $self ) { 1 }
	sub AUTOLOAD ( $self ) { $self }

	sub trace {}
	sub fatal {}
	sub debug {}
	sub error {}
	sub warn  {}
	sub info  {}

	sub is_trace { 0 }
	sub is_fatal { 0 }
	sub is_debug { 0 }
	sub is_error { 0 }
	sub is_warn  { 0 }
	sub is_info  { 0 }
	}


1;
