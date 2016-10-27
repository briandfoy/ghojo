use v5.24.0;
use feature qw(signatures);
no warnings qw(experimental::signatures);

=encoding utf8

=head2 Issues

=over 4

=item * issues( USER, REPO, CALLBACK, HASHREF )

=item * all_issues( USER, REPO, CALLBACK, HASHREF )

=item * open_issues( USER, REPO, CALLBACK, HASHREF )

=item * closed_issues( USER, REPO, CALLBACK, HASHREF )

Get the information for all the labels of a repo.

The keys of the HASHREF can be:

	milestone   integer     If an integer is passed, it should
	            or string   refer to a milestone by its number field.
	                        If the string * is passed, issues
	                        with any milestone are accepted.
	                        If the string none is passed, issues
	                        without milestones are returned.

	state       string      Indicates the state of the issues
	                        to return. Can be either open, closed,
	                        or all. Default: open

	assignee    string      Can be the name of a user. Pass in
	                        none for issues with no assigned user,
	                        and * for issues assigned to any user.

	creator     string      The user who created the issue.

	mentioned   string      A user who's mentioned in the issue.

	labels      string      A list of comma separated label names.
	                        Example: bug,ui,@high

	sort        string      What to sort results by. Can be either created,
	                        updated, comments. Default: created

	direction   string      The direction of the sort. Can be either
	                        asc or desc. Default: desc

	since       string      Only issues updated at or after this time
	                        are returned. This is a timestamp in ISO
	                        8601 format: YYYY-MM-DDTHH:MM:SSZ.

=cut

sub issues ( $self, $owner, $repo, $callback = sub { } , $query = { 'state' => 'open' } ) {
	state $expected_status = 200;

	my $url = $self->query_url( "/repos/%s/%s/issues", [ $owner, $repo ], $query );
	$self->logger->trace( "Query URL is $url" );
	my $results = $self->paged_get(
		"/repos/%s/%s/issues",
		[ $owner, $repo ],
		$callback,
		$query
		);
	}

sub Ghojo::PublicUser::all_issues ( $self, $user, $repo, $callback = sub { $_[0] }, $query = {} ) {
	$query->{'state'} = 'all';
	$self->issues( $user, $repo, $callback, $query );
	}

sub Ghojo::PublicUser::open_issues ( $self, $user, $repo, $callback = sub { $_[0] }, $query = {} ) {
	$query->{'state'} = 'open';
	$self->issues( $user, $repo, $callback, $query );
	}

sub Ghojo::PublicUser::closed_issues ( $self, $user, $repo, $callback = sub { $_[0] }, $query = {} ) {
	$query->{'state'} = 'closed';
	$self->issues( $user, $repo, $callback, $query );
	}

=item * issue( USER, REPO, NUMBER )

Get the information for a particular label.

It returns a hashref:

	{
	'color' => '1d76db',
	'url' => 'https://api.github.com/repos/briandfoy/test-file/labels/Win32',
	'name' => 'Win32'
	}

This implements C<GET /repos/:owner/:repo/labels/:name> from L<http://developer.github.com/v3/issues/labels/>.

=cut

sub Ghojo::PublicUser::issue ( $self, $user, $repo, $number ) {
	my $query_url = $self->query_url( "/repos/%s/%s/issues/%d", $user, $repo, $number );
	$self->logger->trace( "Query URL is $query_url" );
	my $tx = $self->ua->get( $query_url );
	$tx->res->json;
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
