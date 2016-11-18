use v5.24.0;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Endpoint::Labels;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo::Endpoint::Labels - The endpoints that deal with labels

=head1 SYNOPSIS

	use Ghojo;

	my $ghojo = Ghojo->new( ... );

	my $result = $ghojo->labels( $owner, $repo );
	if( $result->is_success ) {
		my $labels = $result->values;  # A Mojo::Collection object
		}

=head1 DESCRIPTION

This section implements the endpoints that deal with labels.

=head2 Labels

=over 4

=cut

=item * labels( OWNER, REPO [, CALLBACK] )

Get the information for all the labels of a repo. If the result is a
success, the value is a L<Mojo::Collection> object representing the
list of labels.

	my $results = $ghojo->labels( $owner, $repo );
	if( $results->is_success ) {
		$results->values->each( sub { say $_->name } );
		}

	# or with a callback
	my $results = $ghojo->labels( $owner, $repo, $callback );

Returns a L<Mojo::Collection> object with the hashrefs representing
labels. Each item is a hash blessed into C<Ghojo::Data::Label>.

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::labels ( $self, $owner, $repo, $callback = sub { $_[0] } ) {
	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/labels',
		endpoint_params => { owner => $owner, repo => $repo },
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Label',
		);
	}

=item * get_label( USER, REPO, LABEL_NAME )

Get the information for a particular label.

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_label ( $self, $owner, $repo, $name ) {
	$self->get_single_resource(
		endpoint        => '/repos/:owner/:repo/labels/:name',
		endpoint_params => { owner => $owner, repo => $repo, name => $name },
		bless_into      => 'Ghojo::Data::Label',
		);
	}

=item * create_label( OWNER, REPO, LABEL_NAME [, COLOR] )

Create a new label. The LABEL_NAME is a string and the COLOR is
a six digit hexadecimal RGB color specification (without the #).
The default color is C<FF0000>.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::create_label ( $self, $owner, $repo, $name, $color = 'FF0000' ) {
	$color =~ s/\A#//;

	$self->post_single_resource(
		endpoint        => '/repos/:owner/:repo/labels',
		endpoint_params => { owner => $owner, repo => $repo },
		json    => {
			name  => $name,
			color => $color,
			},
		);
	}

=item * update_label( OWNER, REPO, NAME, HASH )

This one is a bit tricky. You need to specify the current name, but
also the new name or new color (or both).

	# update both name and color
	$ghojo->update_label( $owner, $repo, $name, { name => $new_name, color => $color } );

	# update color only
	$ghojo->update_label( $owner, $repo, $name, { color => $color } );

	# update name only
	$ghojo->update_label( $owner, $repo, $name, { name => $new_name } );

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::update_label ( $self, $owner, $repo, $name, $args ) {
	$args->{color} =~ s/\A#// if exists $args->{color};

	$self->patch_single_resource(
		endpoint        => '/repos/:owner/:repo/labels/:name',
		endpoint_params => { owner => $owner, repo => $repo, name => $name },
		json            => $args,
		query_profile   => {
			params => {
				name  => qr/\S/,
				color => qr/\A[0-9a-f]{6}\z/i,
				},
			},
		);
	}

=item * delete_label( OWNER, REPO, LABEL_NAME )

Remove the named label from the repository. This should also remove
that label from every issue.

	$ghojo->delete_label( 'octollama', 'woolkit', 'Hacktoberfest' );

This is part of the authenticated user interface.

L<https://developer.github.com/v3/issues/labels/#delete-a-label>

=cut

sub Ghojo::AuthenticatedUser::delete_label ( $self, $owner, $repo, $name ) {
	$self->entered_sub;

	$self->delete_single_resource(
		endpoint        => '/repos/:owner/:repo/labels/:name',
		endpoint_params => {
			owner => $owner,
			repo  => $repo,
			name  => $name,
			},
		);
	}


=item * get_labels_for_issue( OWNER, REPO, ISSUE_NUMBER, CALLBACK )

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_labels_for_issue ( $self, $owner, $repo, $number, $callback = sub { $_[0] } ) {
	$number = $number->id if eval { $number->can( 'id' ) };

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/issues/:number/labels',
		endpoint_params => { owner => $owner, repo => $repo, number => $number },
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Label',
		);
	}


=item * get_labels_for_all_issus_in_milestone( OWNER, REPO, MILESTONE_ID [, CALLBACK] )

GET /repos/:owner/:repo/milestones/:number/labels
Response
Status: 200 OK
Link: <https://api.github.com/resource?page=2>; rel="next",
      <https://api.github.com/resource?page=5>; rel="last"
[
  {
    "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
    "name": "bug",
    "color": "f29513"
  }
]

This is a public API endpoint.

=cut

sub Ghojo::PublicUser::get_labels_for_all_issus_in_milestone ( $self, $owner, $repo, $milestone_id, $callback = sub { $_[0] } ) {
	$milestone_id = $milestone_id->id if eval { $milestone_id->can( 'id' ) };

	$self->get_paged_resources(
		endpoint        => '/repos/:owner/:repo/milestones/:number/labels',
		endpoint_params => { owner => $owner, repo => $repo, number => $milestone_id },
		callback        => $callback,
		bless_into      => 'Ghojo::Data::Label',
		);
	}


=item * add_labels_to_issue( OWNER, REPO, NUMBER, @LABEL_NAMES )

The NUMBER is the issue number as you see it in the website. It is not
the ID number of the issue.

POST /repos/:owner/:repo/issues/:number/labels

Input

	[
	  "Label1",
	  "Label2"
	]

Response

Status: 200 OK

	[
	  {
		"url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
		"name": "bug",
		"color": "f29513"
	  }
	]

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::add_labels_to_issue ( $self, $owner, $repo, $number, @names ) {
	$number = $number->id if eval { $number->can( 'id' ) };

	$self->post_single_resource(
		endpoint        => '/repos/:owner/:repo/issues/:number/labels',
		endpoint_params => { owner => $owner, repo => $repo, number => $number },
		json            => \@names,
		expected_http_status => 200,
		);
	}


=item * remove_label_from_issue( OWNER, REPO, ISSUE_ID, LABEL_NAME )

DELETE /repos/:owner/:repo/issues/:number/labels/:name
Response
Status: 204 No Content

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::remove_label_from_issue ( $self, $owner, $repo, $number, $name ) {
	$number = $number->id if eval { $number->can( 'id' ) };

	$self->delete_single_resource(
		endpoint        => '/repos/:owner/:repo/issues/:number/labels/:name',
		endpoint_params => { owner => $owner, repo => $repo, number => $number, name => $name },
		);
	}


=item * remove_all_labels_from_issue( OWNER, REPO, ISSUE_ID )

DELETE /repos/:owner/:repo/issues/:number/labels
Response
Status: 204 No Content

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::remove_all_labels_from_issue ( $self, $owner, $repo, $number ) {
	$number = $number->id if eval { $number->can( 'id' ) };

	$self->delete_single_resource(
		endpoint        => '/repos/:owner/:repo/issues/:number/labels',
		endpoint_params => { owner => $owner, repo => $repo, number => $issue_id },
		);
	}


=item * replace_all_labels_for_issue( OWNER, REPO, ISSUE_NUMBER [, LABEL_NAME] );

Removes the named labels from the issue. If you don't specify any
label names, it removes all of the labels.

This is an authenticated endpoint.

=cut

sub Ghojo::AuthenticatedUser::replace_all_labels_for_issue ( $self, $owner, $repo, $number, @names ) {
	$number = $number->id if eval { $number->can( 'id' ) };

	$self->put_single_resource(
		endpoint        => '/repos/:owner/:repo/issues/:number/labels',
		endpoint_params => { owner => $owner, repo => $repo, number => $number },
		json            => \@names,
		);
	}

=back

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
