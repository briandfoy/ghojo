use v5.24.0;
use feature qw(signatures);
no warnings qw(experimental::signatures);

=encoding utf8

=head2 Labels

    # http://developer.github.com/v3/issues/labels/
    labels => { url => "/repos/%s/%s/labels" },
    label  => { url => "/repos/%s/%s/labels/%s" },
    create_label => { url => "/repos/%s/%s/labels", method => 'POST', args => 1 },
    update_label => { url => "/repos/%s/%s/labels/%s", method => 'PATCH', args => 1 },
    delete_label => { url => "/repos/%s/%s/labels/%s", method => 'DELETE', check_status => 204 },
    issue_labels => { url => "/repos/%s/%s/issues/%s/labels" },
    create_issue_label  => { url => "/repos/%s/%s/issues/%s/labels", method => 'POST', args => 1 },
    delete_issue_label  => { url => "/repos/%s/%s/issues/%s/labels/%s", method => 'DELETE', check_status => 204 },
    replace_issue_label => { url => "/repos/%s/%s/issues/%s/labels", method => 'PUT', args => 1 },
    delete_issue_labels => { url => "/repos/%s/%s/issues/%s/labels", method => 'DELETE', check_status => 204 },
    milestone_labels => { url => "/repos/%s/%s/milestones/%s/labels" },

=over 4

=cut

=item * labels( USER, REPO )

Get the information for all the labels of a repo.

Returns a L<Mojo::Collection> object with the hashrefs representing
labels:

	{
	'color' => 'd4c5f9',
	'url' => 'https://api.github.com/repos/briandfoy/test-file/labels/Perl%20Workaround',
	'name' => 'Perl Workaround'
	}

Implements C</repos/:owner/:repo/labels>.

=cut

sub labels ( $self, $owner, $repo ) {
	my $params = [ $owner, $repo ];
	my $url = $self->query_url( "/repos/%s/%s/labels", $params );
	$self->logger->trace( "Query URL is $url" );
	my $tx = $self->ua->get( $url );
	Mojo::Collection->new( $tx->res->json->@* );
	}

=item * get_label( USER, REPO, LABEL )

Get the information for a particular label. It returns a hashref:

	{
	'color' => '1d76db',
	'url' => 'https://api.github.com/repos/briandfoy/test-file/labels/Win32',
	'name' => 'Win32'
	}

Implements C</repos/:owner/:repo/labels/:name>.

=cut

sub get_label ( $self, $user, $repo, $name ) {
	state $expected_status = 200;
	my $params = [ $user, $repo, $name ];
	my $url = $self->query_url( "/repos/%s/%s/labels/%s", $params );
	$self->logger->trace( "Query URL is $url" );

	my $tx = $self->ua->get( $url );
	unless( $tx->code eq $expected_status ) {
		$self->logger->error( sprintf "get_label returned status %s but expected %s", $tx->code, $expected_status );
		$self->logger->debug( "get_label response for [ $user, $repo, $name ] was\n", $tx->res->body );
		return;
		}

	$tx->res->json;
	}

=item * create_label

Create a new label.

Query parameters

	name	string	(Required) The name of the label.
	color	string	(Required) A 6 character RGB color
	                Default is FF0000

Implements C<POST /repos/:owner/:repo/labels>.

=cut

sub create_label ( $self, $owner, $repo, $name, $color = 'FF0000' ) {
	state $expected_status = 201;
	my $params             = [ $owner, $repo ];

	$color =~ s/\A#//;

	my $query = {
		name  => $name,
		color => $color,
		};
	my $url = $self->query_url( "/repos/%s/%s/labels", $params, $query );

	$self->logger->trace( "Query URL is $url" );
	my $tx = $self->ua->post( $url => json => $query );
	my $code = $tx->res->code;

	unless( $code == $expected_status ) {
		my $body = $tx->res->body;
		$self->logger->error( "create_label did not return a $expected_status: $body" );
		return 0;
		}

	return 1;
	}

=item * update_label( OWNER, REPO, NAME, NEW_NAME, NEW_COLOR )

PATCH /repos/:owner/:repo/labels/:name

JSON parameters

	name	string	The name of the label.
	color	string	A 6 character hex code, without the leading #, identifying the color.

Response Status: 200 OK

=cut

sub update_label ( $self, $owner, $repo, $name, $new_name, $color ) {
	state $expected_status = 200;
	my $params             = [ $owner, $repo, $name ];

	$color =~ s/\A#//;

	my $query = {};

	$query->{name}  = $new_name if defined $new_name;
	$query->{color} = $color    if defined $color;

	my $url = $self->query_url( "/repos/%s/%s/labels/%s", $params );

	$self->logger->trace( "update_label: URL is $url" );
	my $tx = $self->ua->patch( $url => json => $query );
	my $code = $tx->res->code;

	unless( $code == $expected_status ) {
		my $body = $tx->res->body;
		$self->logger->error( "create_label did not return a $expected_status: $body" );
		return 0;
		}

	return 1;
	}

=item * delete_label( OWNER, REPO, $NAME )

DELETE /repos/:owner/:repo/labels/:name

Status: 204 No Content

=cut

sub delete_label ( $self, $owner, $repo, $name ) {
	state $expected_status = 204;
	my $params             = [ $owner, $repo, $name ];

	my $url = $self->query_url( "/repos/%s/%s/labels/%s", $params );

	$self->logger->trace( "delete_label: URL is $url" );
	my $tx = $self->ua->delete( $url );
	my $code = $tx->res->code;

	unless( $code == $expected_status ) {
		my $body = $tx->res->body;
		$self->logger->error( "create_label did not return a $expected_status: $body" );
		return 0;
		}

	return 1;
	}


=item * get_labels_for_issue( OWNER, REPO, ISSUE_NUMBER, CALLBACK )

GET /repos/:owner/:repo/issues/:number/labels

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

=cut

sub get_labels_for_issue ( $self, $owner, $repo, $number, $callback = sub { $_[0] } ) {
	state $expected_status = 200;
	my $params             = [ $owner, $repo, $number ];

	my $results = $self->paged_get(
		"/repos/%s/%s/issues/%d/labels",
		[ $owner, $repo, $number ],
		$callback,
		{}
		);
	}


=item * get_labels_for_all_issus_in_milestone

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

=cut

sub get_labels_for_all_issus_in_milestone ( $self, $owner, $repo, $name ) {
	state $expected_status = 200;
	my $params             = [ $owner, $repo, $name ];


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

=cut

sub add_labels_to_issue ( $self, $owner, $repo, $number, @names ) {
	state $expected_status = 200;
	my $params             = [ $owner, $repo, $number ];

	my $url = $self->query_url( "/repos/%s/%s/issues/%s/labels", $params );

	$self->logger->trace( "add_labels_to_issue: URL is $url" );
	my $tx = $self->ua->post( $url => json => \@names );
	my $code = $tx->res->code;

	unless( $code == $expected_status ) {
		my $body = $tx->res->body;
		$self->logger->error( "add_labels_to_issue did not return $expected_status: $body" );
		return 0;
		}

	return 1;
	}


=item * remove_label_from_issue

DELETE /repos/:owner/:repo/issues/:number/labels/:name
Response
Status: 204 No Content

=cut

sub remove_label_from_issue ( $self, $owner, $repo, $name ) {
	state $expected_status = 204;
	my $params             = [ $owner, $repo, $name ];


	}


=item * remove_all_labels_from_issue

DELETE /repos/:owner/:repo/issues/:number/labels
Response
Status: 204 No Content

=cut

sub remove_all_labels_from_issue ( $self, $owner, $repo, $name ) {
	state $expected_status = 204;
	my $params             = [ $owner, $repo, $name ];


	}


=item * replace_all_labels_for_issue

PUT /repos/:owner/:repo/issues/:number/labels
Input
[
  "Label1",
  "Label2"
]
Sending an empty array ([]) will remove all Labels from the Issue.

Response
Status: 200 OK
[
  {
    "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
    "name": "bug",
    "color": "f29513"
  }
]

=cut

sub replace_all_labels_for_issue ( $self, $owner, $repo, $name ) {
	state $expected_status = 200;
	my $params             = [ $owner, $repo, $name ];


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
it under the same terms as Perl itself.

=cut

__PACKAGE__
