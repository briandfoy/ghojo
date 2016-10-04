use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo;

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;

=encoding utf8

=head1 NAME

Ghojo - a Mojo-based interface to the GitHub Developer API

=head1 SYNOPSIS

	use Ghojo;

	my $ghojo = Ghojo->new( {
		username => ...,
		password => ...,
		});

	my $ghojo = Ghojo->new( {
		token => ...,
		} );

	# anonymous, not logged in
	my $ghojo = Ghojo->new( {} );

=head1 DESCRIPTION

Here's a Mojo=based interface to the GitHub Developer's API. I'm
reinventing L<Net::GitHub> and L<Pithub> because I feel like it. I
want to make something for the work I do in the way I like to do it,
but I'll let you use it. This started as a way to download all the
GitHub repo meta data for some analysis of label frequency, then it
got out of control for another customer.

My design goals are:

=over 4

=item * Keep a low dependency development model

=item * Make it easy for casual contributors (so no L<Dist::Zilla>)

=item * Supply a more sophisticated interface over a thin layer over the REST stuff

=item * Don't use Moo(se)? since most of the stuff I want to do is special

=item * Validate the inputs to the API to give better error messages

=item * Better response checking

=back

I'm implementing the parts of the API as I or my customers need them.

If you would like to play with this to change things on GitHub, I
suggest setting up a new user and some repos you don't care about
(perhaps forked from interesting ones). Play with those until you are
satisfied that this code isn't going to delete your life. I also keep
backup clones at Bitbucket just in case.

=cut

=head2  General object thingys

=over 4

=item * new

You can create a new object with providing a username/password pair
or a previously created token.

	# Use a login pair. This will create a token for you.
	my $ghojo = Ghojo->new( {
		username => ...,
		password => ...,
		});

	# pass the token as a string
	my $ghojo = Ghojo->new( {
		token => ...,
		} )

	# read a saved token from a file
	my $ghojo = Ghojo->new( {
		token_file => ...,
		} )

	# look in default token file for saved token
	my $ghojo = Ghojo->new( {
		} )

To get a token, see "Personal Access Tokens" in your GitHub settings
(L<https://github.com/settings/tokens>). Be careful! As soon as you
create it GitHub will show you the token, but that's the last time
you'll see it.

With this constructor, Ghojo will create a new token for you (which will
show up in "Personal Access Tokens"). It will save it in the value
returned by C<token_file>.

=cut

sub new ( $class, $args = {} ) {
	my $self = bless {}, $class;
	$self->setup_logging;

	if( exists $args->{token} ) {
		$self->logger->trace( 'Authorizing with token' );
		$self->add_token( $args->{token} );
		}
	elsif( exists $args->{token_file } ) {
		$self->logger->trace( 'Authorizing with saved token in named file' );
		open my $fh, '<:utf8', $args->{token_file} or
			$self->logger->error( "Could not read token file $args->{token_file}" );
		my $token = <$fh>;
		chomp $token;
		$self->logger->debug( "Token from token_file is <$token>" );
		$self->add_token($token);
		}
	elsif( exists $args->{username} and exists $args->{password} ) {
		$self->logger->trace( 'Authorizing with username and password' );
		my @keys = qw(username password);
		$self->@{@keys} = $args->@{@keys};

		$self->{last_tx} = $self->ua->get( $self->api_base_url );

		$self->create_authorization;

		delete $self->{password};
		}
	elsif( -e $self->token_file ) {
		$self->logger->trace( 'Authorizing with saved token in default file' );
		$self->logger->trace( 'Reading token from file' );
		my $token = do { local( @ARGV, $/ ) = $self->token_file; <> };
		$self->logger->trace( "Token from default token_file is <$token>" );
		$self->add_token( $token );
		}

	return $self;
	}

=item * get_repo_object

Get a repo object which remembers its owner and repo name so you don't
have to pass those parameters for all these general method. This is really
a wrapper around L<Ghojo> that fills in some arguments for you.


=cut

sub get_repo_object ( $self, $owner, $repo ) {
	state $rc = require Ghojo::Repo;
	my $perl = $self->get_repo( $owner, $repo );
	unless( $perl ) {
		$self->logger->error( "Could not find the $owner/$repo repo" );
		return;
		}

	my $obj = Ghojo::Repo->new_from_response( $self, $perl );
	unless( $obj ) {
		$self->logger->error( "Could not make object for $owner/$repo!" );
		return;
		}

	$obj;
	}

=back

=head2 Logging

If L<Log4perl> is installed, Ghojo will use that. Otherwise, it installed
the null logger in L<Ghojo::NullLogger>. That responds to all logging
messages but does nothing.

=over 4

=cut

sub setup_logging ( $self, $conf = __PACKAGE__->logging_conf ) {
	require Log::Log4perl;

	$self->{logger} = do {
		if( eval "require Log::Log4perl; 1" ) {
			Log::Log4perl::init( $conf );
			Log::Log4perl->get_logger;
			}
		else {
			# responds to all methods with nothing.
			Ghojo::NullLogger->new;
			}
		};
	}

=item * logging_conf

Returns the default configuration for L<Log::Log4perl>. If it returns
a non-reference scalar, L<Log::Log4perl> uses that string as the filename
for the configuration. If it's a reference,  L<Log::Log4perl> uses that
as a string that holds the configuration. You can override this method
in a subclass (or redefine it).

To Do: Maybe add this value to the constructor

=cut

sub logging_conf ( $class, $level = $ENV{GHOJO_LOG_LEVEL} ) {
	my $conf = qq(
		log4perl.rootLogger          = $level, Screen

		log4perl.appender.Logfile          = Log::Log4perl::Appender::File
		log4perl.appender.Logfile.filename = test.log
		log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
		log4perl.appender.Logfile.layout.ConversionPattern = [%r] %F %L %m%n

		log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
		log4perl.appender.Screen.stderr  = 1
		log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
		);

	\$conf;
	}

=item * logger

Returns the logger object. Wherever you want to log, you can get to the
logging object through the Ghojo object:

	$self->logger->debug( ... );

=cut

sub logger ( $self ) { $self->{logger} }

=item * traceif( FLAG, MESSAGE )

=item * debugif( FLAG, MESSAGE )

=item * infoif( FLAG, MESSAGE )

=item * warnif( FLAG, MESSAGE )

=item * errorif( FLAG, MESSAGE )

=item * fatalif( FLAG, MESSAGE )

Like the L<Log4perl> methods but adds a FLAG argument. If that argument
is true, it passes on the log message (which still might be logged based
on the log level).

=cut

sub traceif ( $self, $flag, $message ) { $flag ? $self->logger->trace( $message )   : $flag }
sub debugif ( $self, $flag, $message ) { $flag ? $self->logger->debug( $message )   : $flag }
sub infoif  ( $self, $flag, $message ) { $flag ? $self->logger->info( $message )    : $flag }
sub warnif  ( $self, $flag, $message ) { $flag ? $self->logger->warn( $message )    : $flag }
sub errorif ( $self, $flag, $message ) { $flag ? $self->logger->logwarn( $message ) : $flag }
sub fatalif ( $self, $flag, $message ) { $flag ? $self->logger->logdie( $message )  : $flag }

=back

=head2 Authorizing queries

The GitHub API lets you authorize through Basic (with username and password)
or token authorization. These methods handle most of those details.

=over 4

=cut

=item * logged_in_user

=item * username

=item * has_username

The C<username> and C<logged_in_user> are the same thing. I think the
later is more clear, though.

=item * password

=item * has_password

Note that after a switch to token authorization, the password might be
deleted from the object.

=item * token

=item * has_token

Fetch or check that these properties have values. Be careful not to
log these! The program needs to keep the value around!

=cut

sub logged_in_user ( $self ) { $self->username }
sub username ( $self )       { $self->{username} }
sub has_username ( $self )   { !! defined $self->{username} }

sub password ( $self )     { $self->{password} }
sub has_password ( $self ) { !! defined $self->{password} }

sub token ( $self )     { $self->{token} }
sub has_token ( $self ) { !! defined $self->{token} }

=item * auth_string

Returns the C<Authorization> header value, whether it's the token or Basic
authorization.

=cut

sub auth_string ( $self ) {
	if( $self->has_token )         { $self->token_auth_string }
	elsif( $self->has_basic_auth ) { $self->basic_auth_string }
	}

=item * has_basic_auth

Checks that we know the username and password.

=cut

sub has_basic_auth ( $self ) {
	$self->warnif( ! $self->has_username, "Missing username for basic authorization!" );
	$self->warnif( ! $self->has_password, "Missing password for basic authorization!" );
	$self->has_username && $self->has_password
	}

=item * token_auth_string

Returns the value for the C<Authorization> request header, using
Basic authorization. This requires username and password values.

=cut

sub basic_auth_string ( $self ) {
	my $rc = require MIME::Base64;
	return unless $self->has_basic_auth;
	'Basic ' . MIME::Base64::encode_base64(
		join( ':', $self->username, $self->password ),
		''
		);
	}

=item * token_auth_string

Returns the value for the C<Authorization> request header, using
token authorization.

=cut

sub token_auth_string ( $self ) {
	$self->warnif( ! $self->has_token, "Missing token for token authorization!" );
	return unless $self->has_token;
	'token ' . $self->token;
	}

=item * token_file

Returns the value of either the environment variable C<GITHUB_DEV_TOKEN>
or C<.github_token>. If you want some other value, I suggest a subclass
that overrides this method.

=cut

sub token_file ( $self ) { $ENV{GITHUB_DEV_TOKEN} // '.github_token' }

=item * add_token( TOKEN )

Adds the token to the object. After this, the object will try to use
the token authorization in all queries.

=cut

sub add_token ( $self, $token ) {
	chomp $token;
	unless( $token ) {
		$self->logger->error( "There's not token!" );
		return;
		}

	$self->{token} = $token;
	$self->remember_token;
	$self->add_token_auth_to_all_requests;
	return $token;
	}

=item * add_token_auth_to_all_requests( TOKEN )

Installs a start event for the L<Mojo::UserAgent> to add the C<Authorization>
header. You don't need to do this yourself.

=cut

sub add_token_auth_to_all_requests ( $self ) {
	unless( $self->has_token ) {
		$self->logger->logdie( "There is no auth token, so I can't add it to every request!" );
		return 0;
		}

	$self->ua->on( start => sub {
		my( $ua, $tx ) = @_;
		$tx->req->headers->authorization( $self->token_auth_string );
		} );
	}

=item * remember_token

Put the token in a file to use later. You normally don't need to call
this yourself.

=cut

sub remember_token ( $self ) {
	unless( $self->token ) {
		$self->logger->warn( "There is no token to remember!" );
		return;
		}

	if( open my $fh, '>:utf8', $self->token_file ) {
		print $fh $self->token;
		close $fh;
		}
	else {
		$self->logger->warn( "Could not open token file! $!" );
		$self->logger->warn( "Token is " . $self->token );
		}
	}

=back

=head2 Queries

=over 4

=item * ua

Returns the L<Mojo::UserAgent> object.

=cut

sub ua ( $self ) {
	state $rc = require Mojo::UserAgent;
	state $ua = Mojo::UserAgent->new;
	$ua;
	}

=item * api_base_url

The base URL for the API. By default this is C<https://api.github.com/>.

=cut

sub api_base_url ( $self ) { Mojo::URL->new( 'https://api.github.com/' ) }

=item * query_url( PATH, PARAMS_ARRAY_REF, QUERY_HASH )

Creates the query URL. Some of the data are in the PATH, so that's a
sprintf type string that fill in the placeholders with the values in
C<PARAMS_ARRAY_REF>. The C<QUERY_HASH> forms the query string for the URL.

	my $url = query_url( '/foo/%s/%s', [ $user, $repo ], { since => $count } );

=cut

sub query_url ( $self, $path, $params=[], $query={} ) {
	state $api = $self->api_base_url;
	my $modified = sprintf $path, $params->@*;
	my $url = $api->clone->path( $modified )->query( $query );
	}

sub post_json( $self, $query_url, $headers = {}, $hash = {} ) {
	$self->{last_tx} = $self->ua->post( $query_url => $headers => json => $hash );
	}

sub last_tx ( $self ) { $self->{last_tx} }

sub set_paged_get_sleep_time ( $self, $seconds = 3 ) {
	$self->{paged_get}{'sleep'} = 0 + $seconds;
	}
sub paged_get_sleep_time ( $self ) { $self->{paged_get}{'sleep'} }

sub set_paged_get_results_limit ( $self, $count = 10_000 ) {
	$self->{paged_get}{'results_limit'} = $count;
	}
sub paged_get_results_limit ( $self ) { $self->{paged_get}{'results_limit'} }

sub paged_get ( $self, $path, $params = [], $callback=sub{ $_[0] }, $query = {} ) {
	$self->logger->trace( 'In paged_get' );
	my @results;
	my $limit = $self->paged_get_results_limit // 1_000;
	my @next = $self->query_url( $path, $params, $query);
		$self->logger->debug( "Queue is:\n\t", join "\n\t", @next );

	while( @results < $limit and my $url = shift @next ) {
		$self->logger->debug( "query_url is $url" );
		my $tx = $self->ua->get( $url );
		my $link_header = $self->parse_link_header( $tx );
		push @next, $link_header->{'next'} if exists $link_header->{'next'};

		my $array = $tx->res->json;
		foreach my $item ( $array->@* ) {
			push @results, $callback->( $item );
			}
		sleep $self->paged_get_sleep_time;
		}

	Mojo::Collection->new( @results );
	}

# <https://api.github.com/repositories?since=367>; rel="next", <https://api.github.com/repositories{?since}>; rel="first"';
sub parse_link_header ( $self, $tx ) {
	my $link_header = $tx->res->headers->header( 'Link' );
	$self->logger->trace( "Link header is <$link_header>" );
	return {} unless $link_header;

	my @parts = $link_header =~ m{
		<(.*?)>; \s+ rel="(.*?)"
		}xg;

	my %hash = reverse @parts;
	return \%hash;
	}

=back

=head2 Authorizations

This section of the GitHub API allows you to create Personal Access Tokens.

=over 4

=item * authorizations

=cut

sub authorizations ( $self ) {
	state $query_url = $self->query_url( "/authorizations" );
	}

sub get_authorization ( $self ) {
	state $query_url = $self->query_url( "/authorizations/%s" );
	}

sub authorization ( $self, $id ) {
	state $query_url = $self->query_url( "/authorizations/%s" );
	}

=item * is_valid_scope( SCOPE )

Returns a list of all valid scopes.

https://developer.github.com/v3/oauth/#scopes

=cut

sub valid_scopes ( $self ) {
	state $scopes = [ qw(
		user
		user:email
		user:follow
		public_repo
		repo
		repo_deployment
		repo:status
		delete_repo
		notifications
		gist
		read:repo_hook
		write:repo_hook
		admin:repo_hook
		admin:org_hook
		read:org
		write:org
		admin:org
		read:public_key
		write:public_key
		admin:public_key
		read:gpg_key
		write:gpg_key
		admin:gpg_key
		) ];
	}

=item * is_valid_scope( SCOPE )

Returns true if SCOPE is a valid authorization scope.

=cut

sub is_valid_scope ( $self, $scope ) {
	state $scopes = { map { lc $_, undef } $self->valid_scopes };
	exists $scopes->{ lc $scope };
	}

=item * create_authorization

Creates a "Personal Access Token" for the logged in user.

https://developer.github.com/v3/oauth_authorizations/#create-a-new-authorization

=cut

sub create_authorization ( $self, $hash = {} ) {
	state $query_url = $self->query_url( "/authorizations" );
	state $allowed   = [ qw(scopes note note_url client_id client_secret fingerprint) ];
	state $required  = [ qw(note) ];

	$hash->{scopes} //= ['user', 'public_repo', 'repo', 'gist'];
	$hash->{note}   //= 'test purpose ' . time;
	$self->post_json( $query_url, { 'Authorization' => $self->basic_auth_string }, $hash );

	unless( $self->last_tx->success ) {
		my $err = $self->last_tx->error;
		$self->logger->warn( "create_authorizaton failed!" );
		$self->warnif( $err->{code}, "$err->{code} response: $err->{message}" );
		return;
		}

	return unless $self->add_token( $self->last_tx->res->json->{token} );

	$self->token;
	}

sub update_authorization ( $self ) {
	state $query_url = $self->query_url( "/authorizations/%s" );
	url => "/authorizations/%s", method => "PATCH", args => 1
	}

sub delete_authorization ( $self ) {
	state $query_url = $self->query_url( sprintf "/authorizations/%s",  );
	url => "/authorizations/%s", method => "DELETE", check_status => 204
	}

=back

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

This implements C<GET /repos/:owner/:repo/labels/:name> from L<http://developer.github.com/v3/issues/labels/>.

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

sub all_issues ( $self, $user, $repo, $callback = sub { $_[0] }, $query = {} ) {
	$query->{'state'} = 'all';
	$self->issues( $user, $repo, $callback, $query );
	}

sub open_issues ( $self, $user, $repo, $callback = sub { $_[0] }, $query = {} ) {
	$query->{'state'} = 'open';
	$self->issues( $user, $repo, $callback, $query );
	}

sub closed_issues ( $self, $user, $repo, $callback = sub { $_[0] }, $query = {} ) {
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

sub issue ( $self, $user, $repo, $number ) {
	my $query_url = $self->query_url( "/repos/%s/%s/issues/%d", $user, $repo, $number );
	$self->logger->trace( "Query URL is $query_url" );
	my $tx = $self->ua->get( $query_url );
	$tx->res->json;
	}

=back

=head2 Repositories

=over 4

=item * repos

GET /user/repos

	visibility      string
	    Can be one of all, public, or private.
	    Default: all

	affiliation     string	Comma-separated list of values. Can include:
	    * owner
	    * collaborator
	    * organization_member
		Default: owner,collaborator,organization_member

	type            string
		Can be one of all, owner, public, private, member.
		Default: all

	    Will cause a 422 error if used in the same request as
	    visibility or affiliation.

	sort            string
		Can be one of created, updated, pushed, full_name.
		Default: full_name

	direction       string
		Can be one of asc or desc.
		Default: when using full_name: asc; otherwise desc

=cut

sub repos ( $self, $callback = sub {}, $query = {} ) {
	$self->logger->trace( 'In repos' );
	my $perl = $self->paged_get( '/user/repos', [], $callback, $query );
	}


=item * get_repo ( OWNER, REPO )

GET /repos/:owner/:repo

The parent and source objects are present when the repository is a
fork. parent is the repository this repository was forked from, source
is the ultimate source for the network.

=cut

sub get_repo ( $self, $owner, $repo ) {
	state $expected_status = 200;

	my $url = $self->query_url( '/repos/%s/%s', [ $owner, $repo ] );
	my $tx  = $self->ua->get( $url );

	unless( $tx->res->code == $expected_status ) {
		my $json = $tx->res->json;
		if( $json->{message} eq 'Not Found' ) {
			$self->logger->error( "get_repo: repo $owner/$repo was not found" );
			}
		else {
			$self->logger->error( "get_repo: unspecified error looking for $owner/$repo. Code " . $tx->res->code );
			$self->logger->debug( "get_repo: " . $tx->res->body );
			}
		return;
		}

	my $perl = $tx->res->json;
	}

=item * repos_by_username( USERNAME )

GET /users/:username/repos

type	string	Can be one of all, owner, member. Default: owner
sort	string	Can be one of created, updated, pushed, full_name. Default: full_name
direction	string	Can be one of asc or desc. Default: when using full_name: asc, otherwise desc

=cut

sub repos_by_username( $self, $username ) {
	$self->paged_get( '', [ $username ] );

	}

=item * repos_by_organization

GET /orgs/:org/repos
type	string	Can be one of all, public, private, forks, sources, member. Default: all

=cut

sub repos_by_organization( $self, $organization ) {


	}

=item * all_public_repos( CALLBACK, QUERY_HASH )

GET /repositories

since	string	The integer ID of the last Repository that you've seen.

=cut

sub all_public_repos ( $self, $callback = sub {}, $query = {} ) {
	my $perl = $self->paged_get( '/repositories', [], $callback, $query );
	}

=item * edit_repo

	PATCH /repos/:owner/:repo

=cut

sub edit_repo( $self, $owner, $repo, $hash = {} ) {

	}

=item * list_repo_contributors( OWNER, REPO )

GET /repos/:owner/:repo/contributors

anon	string	Set to 1 or true to include anonymous contributors in results.

=cut

sub get_repo_contributors ( $self, $owner, $repo ) {


	}

=item * get_repo_languages

GET /repos/:owner/:repo/languages

=cut

sub get_repo_languages ( $self, $owner, $repo ) {


	}

=item * get_repo_teams

GET /repos/:owner/:repo/teams

=cut

sub get_repo_teams ( $self, $owner, $repo ) {


	}

=item * get_repo_tags

	GET /repos/:owner/:repo/tags


=cut

sub get_repo_tags ( $self, $owner, $repo ) {


	}

=item * delete_repo

DELETE /repos/:owner/:repo

Deleting a repository requires admin access. If OAuth is used, the delete_repo scope is required.

=cut

sub delete_repo ( $owner, $repo ) {

	}

=back

=head2 Organizations

=over 4

=back

=head2 Users

=over 4

=item * get_logged_in_user()

Returns a hash reference representing the authenticated user.

=cut

sub get_logged_in_user ( $self ) {
	$self->logger->trace( 'Getting the authenticated user record' );
	state $expected_status = 200;

	my $url = $self->query_url( '/user' );

	my $tx = $self->ua->get( $url );
	my $code = $tx->res->code;

	unless( $code == $expected_status ) {
		my $body = $tx->res->body;
		$self->logger->error( "get_logged_in_user() did not return $expected_status" );
		$self->logger->debug( $tx->res->body );
		return {};
		}

	$tx->res->json;
	}

=item * update_user( QUERY )


=cut

sub update_user ( $self, $query = {} ) {
	state $expected_status = 200;

	}

=item * get_user( USERNAME )

Returns a hash reference representing the requested user.

=cut

sub get_user ( $self, $user ) {
	state $expected_status = 200;

	my $url = $self->query_url( '/users/%s', [ $user ] );

	my $tx = $self->ua->get( $url );
	my $code = $tx->res->code;

	unless( $code == $expected_status ) {
		my $body = $tx->res->body;
		$self->logger->error( "get_user() did not return $expected_status" );
		$self->logger->debug( $tx->res->body );
		return {};
		}

	$tx->res->json;
	}

=item * get_all_users( CALLBACK )

This will eventually return millions of rows!

=cut

sub get_all_users ( $self, $callback = sub { $_[0] } ) {
	state $expected_status = 200;

	my $results = $self->paged_get(
		"/users", [], $callback, {}
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
it under the same terms as Perl itself.

=cut

__PACKAGE__
