use v5.26;

package Ghojo::Result;
use experimental qw(signatures);

use Ghojo;
use Ghojo::Utils qw(dclone dumper dump_request);

=encoding utf8

=head1 NAME

Ghojo::Result - Meta-data about the API response

=head1 SYNOPSIS

	use Ghojo::Result;

	my $success_result = Ghojo::Result->success( {
		values       => [ ],
		description  => ..., # some string
		message      => ..., # some string
		} );

	my $error_result = Ghojo::Result->error( {
		values       => [ ],
		description  => ..., # some string
		message      => ..., # some string
		error_code   => ..., # something in Ghojo::Constants, perhaps?
		extras       => { },
		} );

	if( $result->is_success ) {
		...
		}

	if( $result->is_error ) {
		...
		}

=head1 DESCRIPTION


=head2 Methods

=head3 Make the object

=cut

sub _new ( $class, $hash ) {
	state $Skip_caller = { # ignore these when looking for the offending method
		map { $_, undef } qw(
			Ghojo::Result::success
			Ghojo::Result::error
			Ghojo::classify_error
			Ghojo::get_paged_resources
			)
		};

	$hash->{success} //= 1;

	my @caller;
	for( my $i = 1; $i <= 5; $i++ ) {
		@caller = caller($i);
		#$class->logger->trace( "Should I skip $caller[3]" );
		next if exists $Skip_caller->{ $caller[3] };
		last;
		}

	$hash->{caller}->@{qw(package filename line sub)}
		= @caller[0..3];

	bless $hash, $class;
	}

=over 4

=item * error( HASH_REF )

	description  - string
	message      - string
	error_code   - positive integer
	extras       - hash ref

=cut

sub error ( $class, $hash = {} ) {
	my $return_hash = {};

	$return_hash->{'success'} = 0;
	$return_hash->{'description'} = $hash->{'description'};
	$return_hash->{'message'}     = $hash->{'message'};

	$return_hash->{'error_code'} =
		defined $hash->{error_code} ? int( $hash->{error_code} ) : 0;

	$return_hash->{'extras'} = do {
		if( ref $hash->{'extras'} eq ref {} ) {
			 $hash->{'extras'};
			}
		else {
			{}
			}
		};

	$class->_new( $return_hash );
	}

=item * success

	description
	values
	message
	extras

=cut

sub success ( $class, $hash = {} ) {
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
			Ghojo->logger->debug( "No proper value for success object" );
			}
		};

	$return_hash->{'extras'} = do {
		if( ref $hash->{'extras'} eq ref {} ) {
			 $hash->{'extras'};
			}
		else {
			{}
			}
		};

	$class->_new( $return_hash );
	}

=back

=head3 Make some summaries

These probably only make sense for errors or failures.

=over 4

=item * short_summary

Show a short summary of the error.

=item * long_summary

Still a summary, but with a bit more info.

=item * short_dump

Dump most of the stuff in the object, but leave out the really big
objects (such as the Mojo::Transaction object).

=item * dump

Dump everything.

=back

=cut

sub short_summary ( $self ) {
	my @v = (
		$self->{extras}{args}{endpoint},
		$self->{extras}{verb},
		$self->{message},
		$self->{description},
		);

	return sprintf <<~'HERE', @v;
	Endpoint: %s
	Verb: %s
	Message: %s
	Description: %s
	HERE
	}

sub long_summary ( $self ) {
	my $extras = $self->extras;

	my @v = (
		$extras->{args}{endpoint},
		$extras->{verb},
		$self->message,
		$self->description,
		);

	my $request = do {
		if( ! $extras ) { '<something seriously wrong>' }
		elsif( exists $extras->{tx} ) { dump_request( $extras->{tx} ) }
		else                   { '<No request>' }
		};
	my $headers = do {
		if( ! $extras ) { '<something seriously wrong>' }
		elsif( exists $extras->{tx} ) { $extras->{tx}->result->headers->to_string }
		else                   { '<No response>' }
		};

	return sprintf <<~'HERE', @v, $request, $headers;
		Endpoint: %s
		Verb: %s
		Message: %s
		Description: %s

		REQUEST --------------------
		%s

		RESPONSE HEADERS-------------------
		%s

		HERE
	}

sub short_dump ( $self ) {
	my %clone = %$self;
	delete $clone{extras}{tx};
	$clone{extras}{headers}{Authorization} = '*****';
	$clone{extras}{url} = "$clone{url}";
	dumper( \%clone )
	}

sub dump ( $self ) { dumper( $self ) }

=head3 Inspect the object

=over 4

=item * is_success

Returns true if the result didn't have a problem. If this returns
true, the result of C<error> should be undef and the C<values> method
returns a L<Mojo::Collection> object that represents what you normally
think of as the return values of a method.

If it is false, something bad happened and you should be able to call
C<message()> to get the message.

=cut

sub is_success ( $self ) { $self->{success} }

=item * is_error

A string that describes the error. This is undef if the result is
not an error, and is defined if it is an error (almost a mirror of
C<is_success>). The return value of C<is_success> is undef if C<error> is true.

=cut

sub is_error ( $self ) { ! $self->is_success }

=item * error_code

A number that indentifies the error. Make these unique and you can
use it to look up messages and strings in an internationalized
dictionary.

This returns undef if the result was a success.

=cut

sub error_code ( $self ) { $self->is_success ? () : $self->{error_code} }

=item * description

A string that describes the attempted operation. Make this any string
that makes sense to you. It should be general to the operation and not
the particular result.

=cut

sub description ( $self, $description = undef ) {
	$self->{description} = $description if defined $description;
	$self->{description} // 'No one added a reason for this result'
	}

=item * message

A string that describes what happened for this particular result. Think
of this like an explanation (most likely for the failure).

=cut

sub message ( $self, $message = undef ) {
	$self->{message} = $message if defined $message;
	$self->{message} // 'No one added a reason for this result'
	}

=item * values

If the result is a success, these are what you normally think of as
the return values of the method. This is an L<Mojo::Collection>
object.

=cut

sub values ( $self ) { $self->is_success ? $self->{values} : Mojo::Collection->new() }

=item * single_value

If you're expecting a single return value as the result, you can get
it here.

=cut

sub single_value ( $self ) { scalar $self->values->first }

=item * value_count

If the result is a success, this is the count of what you normally think of as
the return values of the method. This returns an ordinal number.

This returns undef (or the empty list) is the result was an error.

=cut

sub value_count ( $self ) { $self->is_success ? $self->values->size : () }

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

sub extras ( $self, $extras = undef ) {
	$self->{extras} = {} unless exists $self->{extras};
	$self->{extras} = $extras if defined $extras;
	$self->{extras};
	}

=item * add_extras( KEY => VALUE, KEY => VALUE )

Add the keys and values to the extras entry. Returns the object.
=cut

sub add_extras ( $self, %args ) {
	$self->{extras} = {} unless exists $self->{extras};
	foreach my $key ( keys %args ) {
		$self->{extras}{$key} = $args{$key};
		}

	return $self;
	}

=back

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
sub subroutine ( $self ) { $self->{caller}{'sub'} }

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

__END__
https://developer.github.com/v3/#client-errors
