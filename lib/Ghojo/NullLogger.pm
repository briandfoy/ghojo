use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

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

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Ghojo::NullLogger 0.001 {
	sub new ( $class ) { bless { }, $class }
	sub is_null_logger ( $self ) { 1 }
	sub AUTOLOAD ( $self ) { $self }
	}

1;
