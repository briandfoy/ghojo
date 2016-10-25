use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

=encoding utf8

=head1 NAME

Ghojo::Result - Meta-data about the API response

=head1 SYNOPSIS

	use Ghojo::Result;

	my $result = Ghojo::Result->new(
		success      => ..., # true or false
		values       => [ ],
		description  => ..., # some string
		error        => ..., # some string
		error_code   => ..., # a number unique to this error
		);

=head1 DESCRIPTION


=head2 Methods

=head3 Make the object

=cut

sub _new ( $class, $hash ) {
	my $self = bless $hash, $class;

	$self->{caller}->@{qw(package filename line sub)}  = (caller(2))[0..3];

	$self;
	}

=over 4

=item * new_error

	description  - string
	message      - string
	error_code   - positive integer
	extras       - hash ref

=cut

sub make_error ( $class, $hash = {} ) {
	my $return_hash = {};

	$return_hash->{'success'} = 0;
	$return_hash->{'description'} = $hash->{'description'};
	$return_hash->{'message'}     = $hash->{'message'};

	$return_hash->{'error_code'} =
		defined $hash->{error_code} ? int( $hash->{error_code} ) : 0;

	$return_hash->{'extras'} = do {
		if( ref $return_hash->{'extras'} eq ref {} ) {
			 $return_hash->{'extras'};
			}
		else {
			# XXX error
			}
		};

	$class->_new( $return_hash );
	}

=item * new_success

	description
	values
	message

=cut

sub make_success ( $class, $hash = {} ) {
	my $return_hash = {};
	$return_hash->{'success'} = 1;

	$return_hash->{'values'} = do {
		if( ref $hash->{'values'} eq ref [] ) {
			Mojo::Collection->new( $hash->{'values'}->@* )
			}
		elsif( ! ref $hash->{'values'} ) {
			Mojo::Collection->new( $hash->{'values'} )
			}
		else {
			# XXX error
			}
		};

	$class->_new( $return_hash );
	}

=back

=head3 Inspect the object

=over 4

=item * success

Returns true if the result didn't have a problem. If this returns
true, the result of C<error> should be undef and the C<values> method
returns a L<Mojo::Collection> object that represents what you normally
think of as the return values of a method.

If it is false, something bad happened and you should be able to call
C<error()> to get the message.

=cut

sub success ( $self ) { $self->{success} }

=item * error

A string that describes the error. This is undef if the result is
not an error, and is defined if it is an error (almost a mirror of
C<success>). The return value of C<success> is undef if C<error> is true.

=cut

sub error ( $self ) { ! $self->success }

=item * error_code

A number that indentifies the error. Make these unique and you can
use it to look up messages and strings in an internationalized
dictionary.

This returns undef if the result was a success.

=cut

sub error_code ( $self ) { $self->success ? () : $self->{error_code} }

=item * description

A string that describes the attempted operation. Make this any string
that makes sense to you. It should be general to the operation and not
the particular result.

=cut

sub description ( $self ) { $self->{description} // 'No one has described this operation' }

=item * message

A string that describes what happened for this particular result. Think
of this like an explanation (most likely for the failure).

=cut

sub message ( $self ) { $self->{message} // 'No one added a reason for this result' }

=item * description

A string that describes the attempted operation. Make this any string
that makes sense to you. It should be general to the operation and not
the particular result.

=cut

sub description ( $self ) { $self->{description} // 'Someone did not add a description' }

=item * values

If the result is a success, these are what you normally think of as
the return values of the method. This is an L<Mojo::Collection>
object.

=cut

sub values ( $self ) { $self->success ? $self->{values} : Mojo::Collection->new() }

=item * value_count

If the result is a success, this is the count of what you normally think of as
the return values of the method. This returns an ordinal number.

This returns undef (or the empty list) is the result was an error.

=cut

sub values ( $self ) { $self->success ? $self->values->size : () }

=back

=head3 Extras

=over 4

=item * extras

If the result is an error, this is a hashref of extra information
that the complainer thinks is interesting. For instance, it might
include a reference to a L<Mojo::Transaction> object.

This returns an empty hashref if the result was a success.

These are suggestions for extras:

	http_status - the http status. GitHub uses 400, 403, or 422 for errors
		400 - Bad request for the general errors
		403 - Over rate limit (https://developer.github.com/v3/#rate-limiting)
		409 - Git repo is empty (https://developer.github.com/v3/git/)
		409 - Merge Conflict (https://developer.github.com/v3/repos/deployments/)
		422 - Invalid fields were set
		502 - Bad Gateway (https://developer.github.com/v3/repos/releases/)

	error_name - the names listed in the GitHub API
		missing
		missing_field
		invalid
		already_exists

	tx - the L<Mojo::Transaction> object before the error

=cut

sub extras ( $self ) { $self->success ? {} : $self->{extras} }

=head3  Caller info

=over 4

=item * caller

A hashref respresenting some caller info.

=item * package

=item * file

=item * line

=item * subroutine

These return the caller information for the point where the result
object was created. This might not be useful for finding the point of
the error since this might be far away from it.

=cut
sub caller     ( $self ) { $self->{caller} }

sub package    ( $self ) { $self->{caller}{'package'}    }
sub file       ( $self ) { $self->{caller}{'file'}       }
sub line       ( $self ) { $self->{caller}{'line'}       }
sub subroutine ( $self ) { $self->{caller}{'subroutine'} }


=cut

=back

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

https://developer.github.com/v3/#client-errors
