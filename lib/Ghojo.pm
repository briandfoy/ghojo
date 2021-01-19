use v5.26;
use experimental qw(signatures);

package Ghojo;

use Mojo::Util qw(b64_encode dumper);
use Mojo::JSON qw(decode_json);

# The endpoints are divided into public and authenticated parts
# We'll use this inheritance chain to divide them. The public
# class can't see the stuff in the authorized class, but the
# authorized class can see the public stuff. The object that
# the user gets will be one of these.
#
# There could be higher levels for Access and Authorization
@Ghojo::PublicUser::ISA        = qw(Ghojo);
@Ghojo::AuthenticatedUser::ISA = qw(Ghojo::PublicUser);

use Ghojo::Constants;
use Ghojo::Data;
use Ghojo::Endpoints;
use Ghojo::Result;
use Ghojo::Mixins::SuccessError;

sub DESTROY {}

sub AUTOLOAD ( $self, @ ) {
	$self->entered_sub;
	our $AUTOLOAD;
	my @caller = caller(0);
	$self->logger->trace( "AUTOLOADing $AUTOLOAD from @caller[1,2]" );

	my( $class, $method ) = do {
		if( $AUTOLOAD =~ m/(?<class>.*)::(?<method>.+)/ ) {
			@+{ qw(class method) };
			}
		else {
			() # How did we get here?
			}
		};

	# What about the case where the method hasn't been loaded?

	if( $self->authenticated_user_class->can( $method ) and not $self->handles_authenticated_api ) {
		my $message = "Method [$method] is part of the authenticated user API, but this object only handles the public API";
		$self->logger->error( $message );
		$self->logger->debug( sub { scalar $self->stacktrace(3) } );
		return Ghojo::Result->error({
			message     => $message,
			description => "Authenticate to use [$method]",
			});
		}
	}

# ($package, $filename, $line, $subroutine,
# $hasargs, $wantarray, $evaltext, $is_require) = caller($i);
sub stacktrace ( $self, $level = 1 ) {
	my @callers;
	while( 1 ) {
		my @caller = caller( $level++ );
			# package subroutine filename line
		push @callers, [ @caller[0,3, 1,2] ];
		last unless $caller[0] =~ /^Ghojo/;
		}

	return @callers if wantarray;

	my $string = "Stacktrace\n";
	foreach my $i ( 0 .. $#callers ) {
		$string .= '-->' . ("\t" x $i) .
			sprintf "$i: %s (%s %s)\n", $callers[$i]->@[-3..-1]
		}

	return $string;
	}

our $VERSION = '1.001001';

use Mojo::Collection;
use Mojo::URL;
use Mojo::Util qw(dumper);

=encoding utf8

=head1 NAME

Ghojo - a Mojo-based interface to the GitHub Developer API

=head1 SYNOPSIS

	use Ghojo;

	# authenticated
	my $ghojo = Ghojo->new( {
		username => ...,
		password => ...,
		});

	# authenticated
	my $ghojo = Ghojo->new( {
		token => ...,
		} );

	# anonymous, not logged in
	my $ghojo = Ghojo->new( {} );

=head1 DESCRIPTION

Here's a Mojo-based interface to the GitHub Developer's API. I'm
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

=head2 The API

Parts marked with an * are done.

	Actions
		Artifacts
		Permissions
		Secrets
		Self-hosted runners
		Self-hosted runner groups
		Workflows
		Workflow jobs
		Workflow runs

	Activity
		Events
		Feeds
		Notifications
		Starring
		Watching

	Gists
		Comments

	Git Data
		Blobs
		Commits
		References
		Tags
		Trees

	Integrations
		Integrations
		Installations

	Issues
		Assignees
		Comments
		Events
		Labels
		Milestones
		Timeline

	Migration
		Migrations
		Source Imports

	* Miscellaneous ( Ghojo/Miscellaneous.pm )
		* Emojis
		* Gitignore
		* Licenses
		* Markdown
		* Meta
		* Rate Limit

	Organizations
		Members
		Teams
		Webhooks

	Pull Requests
		Review Comments

	Reactions
		Commit Comment
		Issue
		Issue Comment
		Pull Request Review Comment

	Repositories
		Branches
		Collaborators
		Comments
		Commits
		Contents
		Deploy Keys
		Deployments
		Downloads
		Forks
		Invitations
		Merging
		Pages
		Projects
		Releases
		Statistics
		Statuses
		Traffic
		Webhooks

	Search
		Repositories
		Code
		Issues
		Users
		Legacy Search

	Users  ( Ghojo/Users.pm )
		* Emails
		* Followers
		* Git SSH Keys
		* GPG Keys
		Administration (Enterprise)

	Enterprise
		Admin Stats
		LDAP
		License
		Management Console
		Pre-receive Environments
		Pre-receive Hooks
		Search Indexing
		Organization Administration


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
	# We start off with the public interface. If an authorization works
	# it will rebless the object for the authenticated class name.
	my $self = bless {}, $class->public_user_class;

	$self->setup_logging(
		$args->{logging_conf} ? $args->{logging_conf} : $class->logging_conf
		);

	if( exists $args->{token} ) {
		$self->logger->trace( 'Authenticating with token' );
		$self->add_token( $args->{token} );
		}
	elsif( exists $args->{token_file} ) {
		$self->logger->trace( 'Authenticating with saved token in named file' );
		$self->read_token( $args->{token_file} );
		}
	elsif( exists $args->{username} and exists $args->{password} ) {
		$self->logger->trace( 'Authenticating with username and password' );
		$args->{authenticate} //= 0;
		my $result = $self->login( $args );
		if( $result->is_error ) {
			$self->logger->error( "Could not log in" );
			return;
			}
		$self->logger->debug( "Login was a success" );
		$self->logger->debug( "Class is " . $self->class_name );
		}
	elsif( 0 && -e $self->token_file ) { # still not sure I like this.
		$self->logger->trace( 'Authenticating with saved token in default file' );
		$self->logger->trace( 'Reading token from file' );
		my $token = do { local( @ARGV, $/ ) = $self->token_file; <> };
		$self->logger->trace( "Token from default token_file is <$token>" );
		$self->add_token( $token );
		}

	$self;
	}

=item * class_name

Returns the class name of the object.

=cut

sub class_name ( $self ) { ref $self }

=item * handles_public_api

Returns true if the object can access the public API. This should
always be true, although there might be a time when we need it.

=item * handles_authenticated_api

Returns true if the object can access the authenticated portions of
the API. This does not guarantee access or authorization for a
particular endpoint though.

=cut

sub Ghojo::handles_public_api ( $self )                           { 1 }

sub Ghojo::PublicUser::handles_authenticated_api ( $self )        { 0 }

sub Ghojo::AuthenticatedUser::handles_authenticated_api ( $self ) { 1 }

=item * test_authenticated

Returns true if the object is set up to access the authenticated user
parts of the the API. This will be false unless the object is not the
authenticated user class, but might also be false if it is the right
class but the authentication did not work or was revoked (deleted
token, GitHub ban, etc).

The C</rate_limit> endpoint returns different limits for the public
and authenticated user interface so that's a good way to check for now.

See L<https://developer.github.com/v3/rate_limit/>.

=cut

sub test_authenticated ( $self ) {
	return 0 unless $self->handles_authenticated_api;

	return 1 if $self->is_authenticated_api_rate_limit;

	return 0;
	}


=item * login

Login to GitHub to access the parts of the API that require an
authenticated user. You do not need to do this if you want to use the
public parts of the API.

	username  - (required) The GitHub username
	password  - (required) The GitHub password
	authorize - (optional) If true, create a personal access token.
	            Default: true

If the login was successful, it returns

If you pass C<username> and C<password> to C<new>, Ghojo will
do this step for you.

=cut

sub login ( $self, $args = {} ) {
	$self->entered_sub;

	$self->{$_} = $args->{$_} for ( qw(username password) );
	my $tx = $self->ua->get(
		$self->query_url( '/user' )
			=> { 'Authorization' => $self->basic_auth_string }
		);

	unless( $tx->success ) {
		$self->logger->debug( "Login failed" );

		$self->logger->debug( $tx->res->to_string );
		my $err = $tx->error;

		my @methods = qw( requires_one_time_password requires_authentication is_bad_credentials too_many_login_attempts );
		foreach my $method ( @methods ) {
			$self->logger->debug( "Trying $method" );
			my $error = $self->$method( $tx );
			return $error if defined $error;
			}

		# fallback.
		$self->logger->debug( "Could not figure out the login error" );
		return Ghojo::Result->error( {
			description => 'Login failure',
			message     => 'Undetermined error while logging in',
			error_code  => LOGIN_FAILURE,
			extras      => {
				tx => $tx
				},
			}
			);
		}
	$self->logger->debug( "Login succeeded" );

	bless $self, $self->authenticated_user_class;

	# now we should be ready to proceed
	if( $args->{authorize} ) {
		$self->logger->trace( "Trying to get a token" );
		$tx = $self->ua->get( $self->api_base_url );
		my $result = $self->create_authorization; #needs to call the method in the right class
		return $result if $result->is_error;
		delete $self->{password};
		}
	else {
		$self->add_basic_auth_to_all_requests;
		}

	Ghojo::Result->success;
	}

sub requires_one_time_password ( $self, $tx ) {
	# XXX What is the HTTP status code here?
	my $otp_header = $tx->res->headers->header('x-github-otp') // '';
	return unless $otp_header =~ /required/;
	return Ghojo::Result->error( {
		description => 'Login failure',
		message     => 'This account requires two-factor authentication',
		error_code  => REQUIRES_TWO_FACTOR,
		extras      => {
			tx => $tx
			},
		} );
	}

sub requires_authentication ( $self, $tx ) {
	return unless 401 == $tx->res->code;
	return unless $tx->res->json->{message} eq 'Requires authentication';
	return Ghojo::Result->error( {
		description => 'Login failure',
		message     => "This resource requires authentication",
		error_code  => REQUIRES_AUTHENTICATION,
		extras      => {
			tx => $tx
			},
		} );
	}

sub is_bad_credentials ( $self, $tx ) {
	return unless 401 == $tx->res->code;
	return unless $tx->res->json->{message} eq 'Bad credentials';
	return Ghojo::Result->error( {
		description => 'Login failure',
		message     => "Bad username or password",
		error_code  => BAD_CREDENTIALS,
		extras      => {
			tx => $tx
			},
		} );
	}

sub too_many_login_attempts( $self, $tx ) {
	return unless 403 == $tx->res->code;
	return unless $tx->res->json->{message} =~ m/\AMaximum number/;
	return Ghojo::Result->error( {
		description => 'Login failure',
		message     => "Too many failed login attempts",
		error_code  => TOO_MANY_LOGIN_ATTEMPTS,
		extras      => {
			tx => $tx
			},
		} );
	}
=item * public_user_class

Returns the class name that comprises the parts of the API that
don't need an authenticate user. This is the public part of the interface
and is the default object type the C<< Ghojo->new >> returns if you
don't login.

=cut

sub public_user_class ( $self ) { 'Ghojo::PublicUser' }

=item * authenticate_user_class

Returns the class name that comprises the parts of the API that
require an authenticate user. After a successful C<login>, the Ghojo
object automatically reblesses itself to this class. It's a superset
of the public interface.

=cut

sub authenticated_user_class ( $self ) { 'Ghojo::AuthenticatedUser' }

=item * read_token

Read token from a file and save it in memory.

=cut

sub read_token ( $self, $token_file ) {
	open my $fh, '<:utf8', $token_file or do {
		$self->logger->error( "Could not read token file $token_file" );
		return Ghojo::Result->error(
			description  =>  "Reading token from file",
			message      =>  "Could not read token file $token_file",
			error_code   =>  COULD_NOT_READ_TOKEN_FILE,
			extras       =>  {
				args => [@_],
				}
			);
		};
	chomp( my $token = <$fh> );

	# XXX: There should be something here to check that the string looks like a token
	$self->logger->debug( "Token from token_file is <$token>" );

	$self->add_token($token);

	$self;
	}

=item * get_repo_object

Get a repo object which remembers its owner and repo name so you don't
have to pass those parameters for all these general method. This is really
a wrapper around L<Ghojo> that fills in some arguments for you.

=cut

sub get_repo_object ( $self, $owner, $repo ) {
	state $rc = require Ghojo::Repo;

	my $result = $self->get_repo( $owner, $repo );

	if( $result->is_error ) {
		$self->logger->error( "Could not find the $owner/$repo repo" );
		return Ghojo::Result->error( {
			description => 'Currying repo object',
			message     => "Could not find the $owner/$repo repo",
			error_code  => NO_OWNER_REPO_PAIR,
			extras      => {
				args => [ @_ ]
				},
			propogated => [ $result ],
			} );
		}

	my $response = $result->values->first;

	my $obj = Ghojo::Repo->new_from_response( $self, $response );
	}

=back

=head2 Logging

If L<Log4perl> is installed, Ghojo will use that. Otherwise, it installed
the null logger in L<Ghojo::NullLogger>. That responds to all logging
messages but does nothing.

The constructor accepts the C<logging_conf> argument using the same rules as
C<logging_conf()>.

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

=cut

sub logging_conf ( $class, $level = $ENV{GHOJO_LOG_LEVEL} // 'OFF' ) {
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

sub logger ( $self ) {
	ref $self ? $self->{logger} : Log::Log4perl->get_logger
	}

=item * entered_sub

Emit a trace message that we entered the subroutine. The message will
look the same everywhere we do this.

=cut

sub entered_sub ( $self ) {
	return unless $self->logger->is_trace;
	my @caller = caller(1);

	$self->logger->trace( "Entered $caller[3] from $caller[1] line $caller[2]" );
	}

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

sub traceif ( $self, $flag, $message ) { $flag ? $self->logger->trace(   $message ) : $flag }
sub debugif ( $self, $flag, $message ) { $flag ? $self->logger->debug(   $message ) : $flag }
sub infoif  ( $self, $flag, $message ) { $flag ? $self->logger->info(    $message ) : $flag }
sub warnif  ( $self, $flag, $message ) { $flag ? $self->logger->warn(    $message ) : $flag }
sub errorif ( $self, $flag, $message ) { $flag ? $self->logger->logwarn( $message ) : $flag }
sub fatalif ( $self, $flag, $message ) { $flag ? $self->logger->logdie(  $message ) : $flag }

=back

=head2 Authenticating queries

The GitHub API lets you authenticate through Basic (with username and password)
or token authentication. These methods handle most of those details.

=over 4

=cut

=item * authenticated_user

=item * username

=item * has_username

The C<username> and C<authenticated_user> are the same thing. I think the
later is more clear, though.

=item * password

=item * has_password

Note that after a switch to token authentication, the password might be
deleted from the object.

=item * token

=item * has_token

Fetch or check that these properties have values. Be careful not to
log these! The program needs to keep the value around!

=cut

sub authenticated_user ( $self ) { $self->username }
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
	$self->has_username && $self->has_password
	}

=item * add_basic_auth_to_all_requests

=cut

sub add_basic_auth_to_all_requests ( $self ) {
	$self->entered_sub;
	$self->ua->on( start => sub {
		my( $ua, $tx ) = @_;
		$tx->req->headers->authorization( $self->basic_auth_string );
		} );
	}

=item * token_auth_string

Returns the value for the C<Authorization> request header, using
Basic authorization. This requires username and password values.
If basic authentication is not setup, this return nothing.

=cut

sub basic_auth_string ( $self ) {
	$self->warnif( ! $self->has_username, "Missing username for basic authorization!" );
	$self->warnif( ! $self->has_password, "Missing password for basic authorization!" );

	return Ghojo::Result->error unless $self->has_basic_auth;
	'Basic ' . b64_encode(
		join( ':', $self->username, $self->password ),
		''
		);
	}

=item * token_auth_string

Returns the value for the C<Authorization> request header, using token
authorization. If token authentication is not setup, this return
nothing.

=cut

sub token_auth_string ( $self ) {
	$self->warnif( ! $self->has_token, "Missing token for token authorization!" );
	return Ghojo::Result->error unless $self->has_token;
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
token authorization in all queries.

=cut

sub add_token ( $self, $token ) {
	chomp $token;
	unless( $token ) {
		$self->logger->error( "There's no token!" );
		return Ghojo::Result->error;
		}

	$self->{token} = $token;
	$self->remember_token;
	$self->add_token_auth_to_all_requests;
	bless $self, $self->authenticated_user_class;

	return $token;
	}

=item * add_token_auth_to_all_requests( TOKEN )

Installs a start event for the L<Mojo::UserAgent> to add the C<Authorization>
header. You don't need to do this yourself.

=cut

sub add_token_auth_to_all_requests ( $self ) {
	unless( $self->has_token ) {
		$self->logger->logdie( "There is no auth token, so I can't add it to every request!" );
		return Ghojo::Result->error;
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
		return Ghojo::Result->error;
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
	state $ua = do {
		my $ua = Mojo::UserAgent->new;
		$ua->transactor->name( sprintf "Ghojo %s", __PACKAGE__->VERSION );
		$ua;
	};
	$ua;
	}

=item * api_base_url

The base URL for the API. By default this is C<https://api.github.com/>.

=cut

sub api_base_url ( $self ) { Mojo::URL->new( 'https://api.github.com/' ) }

=item * query_url( PATH, PARAMS_ARRAY_REF, QUERY_HASH )

I don't particularly like this, so I'm working on endpoint_to_url instead.
I don't like the sprintf-like handling. I want to start with the literal
endpoint, such as C</users/:username>.

Creates the query URL. Some of the data are in the PATH, so that's a
sprintf type string that fill in the placeholders with the values in
C<PARAMS_ARRAY_REF>. The C<QUERY_HASH> forms the query string for the URL.

	my $url = query_url( '/foo/%s/%s', [ $user, $repo ], { since => $count } );

=cut

sub query_url ( $self, $path, $params=[], $query={} ) {
	# If we ever supported Enterprise, we have to consider a different
	# way to get the base url. There could be several.
	state $api = $self->api_base_url;
	my $modified = sprintf $path, $params->@*;
	my $url = $api->clone->path( $modified )->query( $query );
	}

=item * endpoint_to_url( END_POINT, REST_PARAMS_HASH, QUERY_PARAMS_HASH )

Translates an endpoint, such as C</users/:username> to the URL to
access. Returns a L<Ghojo::Result>. If the operation is successful,
the value in the result object is a L<Mojo::URL> object.

The REST_PARAMS_HASH has values for the names in the enpoint (such
as C<:username> in this example). The QUERY_PARAMS_HASH hash translates into
the GET query string.

	$self->endpoint_to_url(
		'/users/:username'
		=> {  # parameters in the path
			username => 'octocat',
			}
		=> { # query_string
			foo => 'bar'
			}
		);

TODO XXX: There are a couple of complicated query setups that require
extra handling. This just squirts the hash to L<Mojo::URL>'s query.

=cut

sub endpoint_to_url ( $self, $endpoint, $rest_params = {}, $query_params = {} ) {
	state $api = $self->api_base_url;

	my $copy = $endpoint;

	foreach my $key ( keys $rest_params->%* ) {
		$copy =~ s/:$key/$rest_params->{$key}/;
		}

	if( my @missing_rest_params = $copy =~ m|/:(.*?)/|g ) {
		foreach my $param ( @missing_rest_params ) {
			$self->logger->warn( "Missing parameter [$param] for endpoint [$endpoint]" )
			}
		return Ghojo::Result->error;
		}

	my $url = $api->clone->path( $copy )->query( $query_params );

	return Ghojo::Result->success( {
		values => [ $url ]
		} );
	}

sub validate_profile ( $self, $args, $profile ) {
	my @caller = caller(2);
	my $description = "Validating parameters for $caller[3]";

	# profile needs to be a hash ref and
	unless( ref $profile eq ref {} and exists $profile->{params} ) {
		return Ghojo::Result->error({
			description  => $description,
			message      => 'Error specifying profile',
			error_code   => PROFILE_ERROR,
			extras       => {
				args       => $args,
				profile    => $profile,
				stacktrace => [ $self->stacktrace(1) ],
				},
			});
		}

	my @extra_keys   = grep { ! exists $profile->{params}{$_} } keys $args->%*;

	$profile->{required} //= [];
	my @missing_keys = grep { ! exists $args->{$_} } $profile->{required}->@*;
	my $extra   = scalar @extra_keys   ? ( 'Extra arguments: '   . join( ", ", @extra_keys   ) ) : '';
	my $missing = scalar @missing_keys ? ( 'Missing arguments: ' . join( ", ", @missing_keys ) ) : '';

	my $message = $extra;
	$message .= "\n" if $message;
	$message .= $missing if $missing;

	if( $message ) {
		return Ghojo::Result->error({
			description  => $description,
			message      => $message,
			error_code   => PROFILE_INPUT_ERROR,
			extras       => {
				args       => $args,
				profile    => $profile,
				stacktrace => [ $self->stacktrace(1) ],
				},
			});
		}

	my @errors;
	foreach my $key ( keys $args->%* ) {
		my $validator = $profile->{params}{$key};

		push @errors, do {
			if( ref $validator eq ref qr// ) {
				$args->{$key} =~ $validator ? () : "$key did not match $validator";
				}
			elsif( ref $validator eq ref sub {} ) {
				$validator->( $args->{$key} ) ? () : "$key did not return true value for coderef";
				}
			elsif( ref $validator eq ref [] ) {
				grep { $args->{$key} eq $_ } $validator->@* ? () : "$key was not one of <@$validator>";
				}
			elsif( ! ref $validator ) {
				$args->{$key} eq $validator ? () : "$key was not $validator";
				}
			};
		}

	if( @errors ) {
		my $message = join "\n", @errors;
		return Ghojo::Result->error({
			description  => $description,
			message      => $message,
			error_code   => PROFILE_VALIDATION_ERROR,
			extras       => {
				args       => $args,
				profile    => $profile,
				stacktrace => [ $self->stacktrace(1) ],
				},
			});
		}

	return Ghojo::Result->success({
		description  => $description,
		message      => 'Parameters validate',
		});
	}

sub post_json( $self, $query_url, $headers = {}, $hash = {} ) {
	$self->{last_tx} = $self->ua->post( $query_url => $headers => json => $hash );
	}

sub last_tx ( $self ) { $self->{last_tx} }


# designed for responses that return everything at once (and not
# paged)

sub default_data_class ( $self ) { 'Ghojo::Data::Unspecified' }

BEGIN {
	# This stuff will help with rate limiting.
	my $query_count;
	sub increment_query_count ( $self ) { $query_count++   }
	sub get_query_count       ( $self ) { $query_count     }
	sub clear_query_count     ( $self ) { $query_count = 0 }
	};

sub single_resource ( $self, $verb, %args  ) {
	$self->entered_sub;
	$self->logger->debug( sub { dumper( \%args ) } );

	# validate the query parameters
	if( exists $args{query_params} and exists $args{query_profile} ) {
		my $result = $self->validate_profile( @args{ qw(query_params query_profile) } );
		return $result if $result->is_error;
		}

	# validate the endpoint parameters
	if( exists $args{endpoint_params} and exists $args{endpoint_profile} ) {
		my $result = $self->validate_profile( @args{ qw(endpoint_params endpoint_profile) } );
		return $result if $result->is_error;
		}

	my $url_result = $self->endpoint_to_url( @args{ qw(endpoint endpoint_params query_params) } );
	return $url_result if $url_result->is_error;

	my $url = $url_result->values->first;
	$self->logger->debug( "URL to single resource is <$url>" );

	state $allowed_verbs = { # with default expected http statuses
		get      => 200,
		post     => 201,
		put      => 200,
		patch    => 200,
		'delete' => 204,
		};

	# Check that we have an allowed verb. You shouldn't call this
	# directly in application code, but this check ensures that
	# $verb is something we can handle.
	$verb = lc $verb;
	return Ghojo::Result->error( {
		description => 'Fetching a single resource',
		message     => "Unknown HTTP verb $verb",
		error_code  => UNKNOWN_HTTP_VERB,
		extras      => {
			args => [ @_ ],
			},
		} ) unless exists $allowed_verbs->{$verb};

	# turn every value for expected_http_status into an array. There
	# are some operations that have more than one HTTP status that
	# signifies normal operation.
	$args{expected_http_status} //= $allowed_verbs->{$verb};
	$args{expected_http_status} = [ $args{expected_http_status} ]
		unless ref $args{expected_http_status} eq ref [];

	# Before we make the query, check that we have the right scope.
	# When you create a personal access token, you can specify which
	# scopes you want. When we stored the token, we asked for the list
	# of scopes.
	#
	# There are also scopes for teams and orgs
	unless( $self->has_scopes( $args{required_scopes} ) ) {
		$self->logger->error( "This operation does not have the required scopes []" );
		return Ghojo::Result->error;
		}

	# XXX: Check rate status before we try this?
	my @args = ( $url );
	my %headers;

	$headers{'Authorization'} = $self->auth_string if $self->auth_string;

	# this is the base content-type for the API
	$headers{'Accept'} = $args{accepts} // 'application/vnd.github.v3+json';
	$self->logger->debug( "Accept header is: $headers{'Accept'}" );

	# XXX maybe check that this makes sense
	$headers{'Content-type'}  = $args{content_type} if $args{content_type};

	push @args, \%headers;

	if( exists $args{json} ) {
		push @args, 'json' => $args{json};
		}

	if( exists $args{form} ) {
		push @args, 'form' => $args{form};
		}

	if( exists $args{body} ) {
		push @args, $args{body}
		}

	$self->logger->debug( sub { "Args to ua are:\n" . dumper( \@args ) } );

	# XXX: also look in %args for 'json' and 'form'
	my $tx = $self->ua->$verb( @args );
	$self->logger->debug( "Request was:\n" . $tx->req->to_string );
	$self->increment_query_count;

	# check that status is one of the expected statuses
	my $status = $tx->res->code;
	$self->logger->debug( "HTTP status was [$status]" );

	# if it was the expected status, take the JSON in the
	# message body and bless it into the right class

	# Can't have raw_content and bless_into at the same time?
	if( grep { $_ == $status } $args{expected_http_status}->@* ) {
		my $data = $args{raw_content} ? $tx->res->body : $tx->res->json;
		my $result = $self->bless_into( $data, \%args );
		return $result if eval { $result->is_error };
		return Ghojo::Result->success( {
			values => [ $data ],
			extras => {
				tx => $tx,
				},
			} )
		}

	$self->logger->debug( sub {
		"Got HTTP status $status while expecting one of "
		. join ', ', $args{expected_http_status}->@*
		} );

	# by this time an error has definitely occurred, so figure out
	# what it is
	$self->classify_error( $url, $tx );
	}

sub classify_error ( $self, $url, $tx ) {
	my $status = $tx->res->code;
	my $verb   = lc $tx->req->method;

	if( $status == 404 and $verb eq 'get' ) {
		return Ghojo::Result->error( {
			description  => 'Fetching a single resource',
			message      => 'Got a 404 response. Object not found!',
			error_code   => RESOURCE_NOT_FOUND,
			extras => {
				url => $url,
				tx  => $tx,
				},
			} )
		}

	# XXX: if it's forbidden, what should we do about what we think
	# we good credentials? Check that the token is still valid?
	# try to re-login?
	if( $status == 401 ) {
		$self->logger->debug( "The request requires authentication!" );
		return Ghojo::Result->error({
			message => "The request requires authentication!",
			extras => {
				tx => $tx,
				},
			});
		}

	if( $status == 403 ) {
		my $message = "The request was forbidden!";
		$self->logger->debug( "The request was forbidden!" );

		my $json = eval { $tx->res->json };

		if( $json->{message} =~ /(API rate limit exceeded for \S+)/ ) {
			$message = $1;
			}
		$self->logger->debug( "$message" );

		return Ghojo::Result->error({
			message => $message,
			extras => {
				tx => $tx,
				},
			});
		}

	if( $status == 415 ) {
		$self->logger->debug( "The request requires additional media types in Accept" );
		return Ghojo::Result->error({
			message => "The request requires additional media types in Accept!",
			extras => {
				tx => $tx,
				},
			});
		}

	if( $status == 422 ) {
		$self->logger->debug( "The request was invalid" );
		return Ghojo::Result->error({
			message => "The request was invalid",
			extras => {
				tx => $tx,
				},
			});
		}

	if( 400 <= $status and $status <= 499 ) {
		$self->logger->debug( "Unhandled 4xx request" );
		return Ghojo::Result->error({
			message => "Unhandled 4xx request",
			extras => {
				tx => $tx,
				},
			});
		}

	return Ghojo::Result->error({
		message => "Unhandled error",
		extras => {
			tx => $tx,
			},
		});
	}

sub get_single_resource ( $self, %args ) {
	$self->entered_sub;
	$self->single_resource( GET => %args );
	}

sub post_single_resource ( $self, %args ) {
	$self->entered_sub;
	$self->single_resource( POST => %args );
	}

sub put_single_resource ( $self, %args ) {
	$self->entered_sub;
	$self->single_resource( PUT => %args );
	}

sub patch_single_resource ( $self, %args ) {
	$self->entered_sub;
	$self->single_resource( PATCH => %args );
	}

sub delete_single_resource ( $self, %args ) {
	$self->entered_sub;
	$self->single_resource( DELETE => %args );
	}

sub bless_into ( $self, $ref, $args ) {
	return unless $args->{bless_into};
	unless( $args->{bless_into} =~ m/\A [A-Za-z][A-Za-z0..9_]* (::[A-Za-z][A-Za-z0..9_]*)* \z/x ) {
		return Ghojo::Result->error( {
			description => "Fetching single resource",
			message     => "Bad package name for bless_into: $args->{bless_into}",
			error_code  => BAD_PACKAGE_NAME,
			extras      => {
				args => $args,
				},
			} );
		}

	eval "require $args->{bless_into}";
	bless $ref, $args->{bless_into};
	}

# this is blocking, but there's not another way around it
# you don't know the next one until you see the response
sub get_paged_resources ( $self, %args ) {
	$self->entered_sub;

	# validate the endpoint parameters
	if( exists $args{endpoint_params} and exists $args{endpoint_profile} ) {
		my $result = $self->validate_profile( @args{ qw(endpoint_params endpoint_profile) } );
		return $result if $result->is_error;
		}

	# validate the query parameters
	if( exists $args{query_params} and exists $args{query_profile} ) {
		my $result = $self->validate_profile( @args{ qw(query_params query_profile) } );
		return $result if $result->is_error;
		}

	my $url_result = $self->endpoint_to_url( @args{ qw(endpoint endpoint_params query_params) } );
	return $url_result if $url_result->is_error;

	my $url = $url_result->values->first;
	$self->logger->debug( "URL to single resource is <$url>" );

	my @results;

	$args{callback} //= sub { 1 };
	unless( ref $args{callback} eq ref sub {} ) {
		$self->logger->error( "Callback argument is not a subroutine reference!" );
		return Ghojo::Result->error({
			message     => "The callback entry was not a coderef",
			});
		}

	$args{limit}   //= 1000;
	$args{'sleep'} //=    3;

	my @queue = ( $url );
	$self->logger->debug( "Queue is @queue" );
	LOOP: while( @results < $args{limit} and my $url = shift @queue ) {
		state $error_count = 0;
		$self->logger->trace( "Fetching URL $url" );
		my $tx = $self->ua->get( $url );

		unless( $tx->res->is_success ) {
			return $self->classify_error( $url, $tx );
			}
		my $link_header = $self->parse_link_header( $tx );
		$self->logger->trace( sprintf "next is <%s>", $link_header->{'next'} // '' );
		push @queue, $link_header->{'next'} if exists $link_header->{'next'};

		# The workflow API really screwed the pooch by returning a
		# hash with a count and then a key that has the array. It's
		# unlike the rest of the API. Hence, result_key.
		my $json = eval { $tx->res->json };
		$self->logger->debug( "Result JSON ref type is " . ref($json) );
		$self->logger->debug( sprintf "result_key is <%s>", $args{result_key} // '' );

		if( ref($json) eq ref({}) and ! exists $args{result_key} ) {
			$self->logger->debug( "JSON is a hash, should be an error" );
			return Ghojo::Result->error({
				description => "Error fetching paged resource",
				message     => "The paged response is a hash and result key is not set",
				});
			}

		my $array = do {
			if( exists $args{result_key} ) { $json->{$args{result_key}} }
			else                           { $json }
			};

		foreach my $item ( $array->@* ) {
			$self->logger->trace( "get_paged_resources processing item ", @results + 1 );
			my $result = $self->bless_into( $item, \%args );
			return $result if eval { $result->is_error };
			$result = $args{callback}->( $item, $tx );
			last LOOP unless defined $result;
			push @results, $result;
			}

		$error_count = 0;
		sleep $args{'sleep'} unless @queue == 0;
		}

	Ghojo::Result->success({
		values => \@results,
		});
	}

sub set_paged_get_sleep_time ( $self, $seconds = 3 ) {
	$self->logdie( "paged_get is deprecated" );
	}
sub paged_get_sleep_time ( $self ) { $self->logdie( "paged_get is deprecated" ); }

sub set_paged_get_results_limit ( $self, $count = 10_000 ) {
	$self->logdie( "paged_get is deprecated" );
	}
sub paged_get_results_limit ( $self ) { $self->logdie( "paged_get is deprecated" ); }

sub paged_get ( $self, $path, $params = [], $callback=sub{ $_[0] }, $query = {} ) {
	$self->logdie( "paged_get is deprecated" );
	}

# <https://api.github.com/repositories?since=367>; rel="next", <https://api.github.com/repositories{?since}>; rel="first"';
sub parse_link_header ( $self, $tx ) {
	my $link_header = $tx->res->headers->header( 'Link' );
	$self->logger->trace( sprintf "next is <%s>", $link_header->{'next'} // '' );
	return {} unless $link_header;

	my @parts = $link_header =~ m{
		<(.*?)>; \s+ rel="(.*?)"
		}xg;

	my %hash = reverse @parts;
	return \%hash;
	}

=item * check_repo( OWNER, REPO )

Checks that the OWNER and REPO are avialable. They might exist but
be hidden to you or the public API.

=cut

sub Ghojo::check_repo ( $self, $owner, $repo ) {
	state $cache = {};
	return $cache->{"$owner/$repo"} if exists $cache->{"$owner/$repo"};

	$cache->{"$owner/$repo"} = do {
		if( ! $self->user_is_available( $owner ) ) {
			Ghojo::Result->error({
				description => "Checking user",
				message     => "User $owner is not available",
				extras      => {
					stacktrace => [ $self->stacktrace(1) ],
					},
				});
			}
		elsif( ! $self->repo_is_available( $owner, $repo ) ) {
			Ghojo::Result->error({
				description => "Checking repository",
				message     => "Repo $owner/$repo is not available (but user $owner is)",
				extras      => {
					stacktrace => [ $self->stacktrace(1) ],
					},
				});
			}
		else {
			Ghojo::Result->success({
				description => "Checking repository",
				message     => "$owner/$repo is available",
				});
			}
		};

	}

=back

=head2 Content types


=over 4

=item * version_raw

	application/vnd.github.VERSION.raw

=cut

sub version_raw { 'application/vnd.github.VERSION.raw' }

=item * version_html

	application/vnd.github.VERSION.html

=cut

sub version_html { 'application/vnd.github.VERSION.html' }

=item * version_object

	application/vnd.github.VERSION.object

=cut

sub version_object { 'application/vnd.github.VERSION.object' }

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A F<LICENSE> file should have accompanied
this distribution.

=cut

__PACKAGE__
