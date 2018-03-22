use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Data::Label;
use parent qw(Ghojo::Data);

=encoding utf8

=head1 NAME

Ghojo::Data::Label - Do the things a label can do

=head1 SYNOPSIS

	use Ghojo::Data;

=head1 DESCRIPTION

This module mostly wraps the actions in L<Ghojo::Endpoint::Labels>
to apply them to specific label objects.

A label has three parts:

=over 4

=item * name

=item * color

=item * url

These methods return the string that represents that value in the label.

=back

Additionally, a label belongs to a repo:

=over 4

=item * owner_repo_name

Returns a list of the owner, repo, and name of the label. This looks
in C<url> to get that info.

=cut

sub owner_repo_name ( $self ) {
	my( $owner, $repo, $name ) = $self->url =~ m|/repos/([^/]+)/([^/]+)/labels/([^/]+)|;
	}

=item * update( GHOJO, HASH )

Updates the label's name or color. The HASH can have keys for C<name> or
C<color> or both. This wraps C<Ghojo::Endpoint::Labels::update_label>
and passes through the result of that operation if there is a failure.
If the update is successful, it updates the label object with the new
name, color, and url.

XXX: What happens to the label ID in that case? Does it matter if the
label ID changes?

=cut

sub update ( $self, $ghojo, $hash ) {
	# XXX: how do I get the ghojo object?
	my $result = $ghojo->update_label( $self->owner_repo_name, $hash );
	return $result if $result->is_error;

	my $new_label = $result->values->first;
	$self->name( $new_label->name );
	$self->color( $new_label->color );
	$self->url( $new_label->url );

	$result->is_success( { values => [ $self ] } );
	}

=item * update_name( GHOJO, NEW_NAME )

Updates the label's name. This merely wraps C<update> so you don't have
to make a hash argument.

=cut

sub update_name ( $self, $ghojo, $new_name ) {
	$self->update( $ghojo, { name => $new_name } );
	}

=item * update_color( GHOJO, NEW_COLOR )

Updates the label's color. This merely wraps C<update> so you don't have
to make a hash argument.

=cut

sub update_color ( $self, $ghojo, $new_color ) {
	$self->update( $ghojo, { color => $new_color } );
	}

=item * assign_to_issue( GHOJO, ISSUE_ID | ISSUE )

Assigns this label to the issue. You can pass the issue ID or an
issue object.

=cut

sub assign_to_issue( $self, $ghojo, $issue_id ) {
	my( $owner, $repo, $name ) = $self->owner_repo_name;
	$ghojo->add_labels_to_issue( $owner, $repo, $issue_id, $name );
	}

=item * remove_from_issue( GHOJO, ISSUE_ID | ISSUE )

Removes this label from the issue. You can pass the issue ID or an
issue object.

=cut

sub remove_from_issue( $self, $ghojo, $issue_id ) {
	my( $owner, $repo, $name ) = $self->owner_repo_name;
	$ghojo->remove_label_from_issue( $owner, $repo, $issue_id, $name );
	}

=item * delete( GHOJO )

Delete's the label.

=cut

sub delete ( $self, $ghojo ) {
	$ghojo->delete_label( $self->owner_repo_name );
	}

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A LICENSE file should have accompanied
this distribution.

=cut

__PACKAGE__
