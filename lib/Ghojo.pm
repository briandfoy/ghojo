use v5.28;
use experimental qw(signatures);

package Ghojo;


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
use Ghojo::Mixins::SuccessError;
use Ghojo::Result;
use Ghojo::Scopes;
use Ghojo::Utils qw(:all);

sub DESTROY {}

sub AUTOLOAD ( $self, @args ) {
	our $AUTOLOAD;

	$self->entered_sub;
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

	state %Verbs = map { $_ => 1 } qw(get post put patch delete);
	if( $method =~ /([a-z]+)_single_resource/ and exists $Verbs{$1} ) {
		return $self->single_resource( uc($1) => @args );
		}

	if( $self->authenticated_user_class->can( $method ) and not $self->handles_authenticated_api ) {
		my $message = "Method [$method] is part of the authenticated user API, but this object only handles the public API";
		$self->logger->error( $message );
		$self->logger->debug( sub { scalar $self->stacktrace(3) } );
		return Ghojo::Result->error({
			message     => $message,
			description => "Authenticate to use [$method]",
			});
		}
	elsif( $self->public_user_class->can( $method ) ) {
		my $message = "Method [$method] is unknown";
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

our $VERSION = '1.001002';

use Mojo::Collection;
use Mojo::URL;
use Storable qw(dclone);

=encoding utf8

=head1 NAME

Ghojo - a Mojo-based interface to the GitHub Developer API

=head1 SYNOPSIS

	use Ghojo;

	# username and password were removed by GitHub. You must use
	# a token.

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
backup clones at Bitbucket and Gitlab just in case.

=cut

=head2 The API

Parts marked with an * are done.

	Actions
		Artifacts
		Cache
		OIDC
		Permissions
		Required Workflows
		Secrets
			Repository
			Organization
			Environment
		Self-hosted runners
		Self-hosted runner groups
		Variables
		Workflows
		Workflow jobs
		Workflow runs

	Activity
		Events
		Feeds
		Notifications
		Starring
		Watching

	Apps

	Billing

	Branches

	Checks

	Codes of conduct

	Code scanning

	Codespaces

	Collaborators

	Commits

	Dependabot

	Dependency Graph

	Deployments

	Emoji

	Gists
		Comments

	Git Data
		Blobs
		Commits
		References
		Tags
		Trees

	Gitignore

	Interactions

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

	Licenses

	Markdown

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

	Packages

	Pages

	Projects (classic)

	Pull Requests
		Review Comments

	Rate limit

	Reactions
		Commit Comment
		Issue
		Issue Comment
		Pull Request Review Comment

	Releases

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

	Secret Scanning

	Security advisories

	Teams

	Users  ( Ghojo/Users.pm )
		* Emails
		* Followers
		* Git SSH Keys
		* GPG Keys
		Administration (Enterprise)

	Repository webhooks


=head2  General object thingys

=over 4

=item * new

You can create a previously created token:

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

# https://docs.github.com/en/rest/overview/api-versions?apiVersion=2022-11-28
sub api_version ( $either ) { '2022-11-28' }

sub new ( $class, $args = {} ) {
	# We start off with the public interface. If an authorization works
	# it will rebless the object for the authenticated class name.
	my $self = bless {}, $class->public_user_class;

	my $level = $args->{log_level} // uc($ENV{GHOJO_LOG_LEVEL} // 'OFF' );

	$self->setup_logging(
		( $args->{logging_conf} ? $args->{logging_conf} : $class->logging_conf($level) )
		);

	my( $trace, $result ) = do {
		if( exists $args->{token} ) {
			( 'token', $self->add_token( $args->{token} ) );
			}
		elsif( exists $args->{token_file} ) {
			( 'saved token in named file <$args->{token_file}>', $self->read_token( $args->{token_file} ) );
			}
		elsif( 0 && -e $self->token_file ) { # still not sure I like this.
			my $message = 'Authenticating with token in default file';
			my $token = $self->read_token( $args->{token_file} );
			my $result = $self->add_token( $token );
			( 'token in default file', $result );
			}
		else { # not authenticating
			( '<not logging in>', Ghojo::Result->success )
			}
		};

	$trace = 'Authenticating with ' . $trace;
	$self->logger->trace( $trace );

	return $result if $result->is_error;

	# If we are auth-ed, we should be able to get the and auth resource
	# This will get us the token scopes too
	# XXX this counts against the rate limit, so maybe just check the
	# rate limit endpoint?
	$result = $self->get_authenticated_user if $self->has_auth;

	if( $result->is_error ) {
		my $message = $result->message;
		$result->message( $trace . ": Authentication failed" );
		return $result;
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
	$self->entered_sub;
	$self->debug( "Reading token from <$token_file>" );

	open my $fh, '<:utf8', $token_file or do {
		$self->logger->error( "Could not read token file $token_file" );
		return Ghojo::Result->error(
			description  =>  "Reading token from file",
			message      =>  "Could not read token file $token_file",
			error_code   =>  COULD_NOT_READ_TOKEN_FILE,
			extras       =>  {
				token_file => $token_file,
				}
			);
		};
	chomp( my $token = <$fh> );

	# XXX: There should be something here to check that the string looks like a token
	$self->logger->debug( "Token from token_file is <$token>" );

	return Ghojo::Result->success;
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
				args => [ $self, $owner, $repo ]
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

sub logging_conf ( $class, $level = uc($ENV{GHOJO_LOG_LEVEL}) // 'OFF' ) {
	my $conf = qq(
		log4perl.rootLogger          = $level, Screen

		log4perl.appender.Logfile          = Log::Log4perl::Appender::File
		log4perl.appender.Logfile.filename = test.log
		log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
		log4perl.appender.Logfile.layout.ConversionPattern = [%r] %F %L %m%n

		log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
		log4perl.appender.Screen.stderr  = 1
		log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout
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

The GitHub API lets you authenticate through token authentication.
These methods handle most of those details.

=over 4

=cut

=item * token

=item * has_token

Fetch or check that these properties have values. Be careful not to
log these! The program needs to keep the value around!

=cut

sub token               ( $self ) {            $self->{token}    }
sub has_token           ( $self ) { !! defined $self->{token}    }

sub has_auth            ( $self ) { $self->has_token }

=item * auth_string

Returns the C<Authorization> header value.

=cut

sub auth_string ( $self ) {
	if( $self->has_token )         { $self->token_auth_string }

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
		return Ghojo::Result->error({
			message     => 'Missing token',
			description => 'Did you forget the argument to new()?',
			});
		}

	$self->{token} = $token;
	# $self->remember_token;  # not sure I want this yet, and not in repo dir
	$self->add_token_auth_to_all_requests;
	bless $self, $self->authenticated_user_class;

	return $self;
	}

=item * add_token_auth_to_all_requests( TOKEN )

Installs a start event for the L<Mojo::UserAgent> to add the C<Authorization>
header. You don't need to do this yourself.

=cut

sub add_token_auth_to_all_requests ( $self ) {
	unless( $self->has_token ) {
		my $message = "There is no auth token, so I can't add it to every request!";
		$self->logger->error( $message );
		return Ghojo::Result->error({
			message => $message
			});
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
		my $message = "There is no token to remember!";
		$self->logger->warn( $message );
		return Ghojo::Result->error({
			message => $message
			});
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

=head3 Personal Access Token scopes

A Personal Access Token is one form of authentication, and each token
can have its own set of permissions. When Ghojo gets a response, it notes
which scopes the response tells it the token has (and tokens can change
their set of scopes).

Ghojo endpoints know which scopes they need, and the process can check
that the token has the right scopes before it makes the request.

Most of this doesn't need to happen at the endpoint level. The innards
can do various checks like this:

	unless( $ghojo->scopes->satisfies( 'workflows' ) ) {
		...
		}

This way, the innards can set appropriate Ghojo::Result error objects
to note which scopes were missing for a failed operation. See
C<single_resource> for example.

In user code, the C<error_code> part of the result should be the
constant C<MISSING_SCOPES>:

	my $result = $ghojo->some_endpoint();
	if( $result->is_error ) {
		say "Missing scopes!" if $result->error_code == MISSING_SCOPES;
		say "Scopes: ", $ghojo->scopes->as_list;
		say "Required: ", $result->extras->{required}->as_list;
		}

=over 4

=item * init_scopes()

Initialize the Ghojo::Scopes object. You can also use this to start
with a fresh object.

=item * scopes()

Return the Ghojo::Scopes object.

=cut

{
my $key = 'token_scopes';

sub init_scopes ( $self ) { $self->{$key} = Ghojo::Scopes->new }
sub scopes      ( $self ) { $self->{$key}                      }
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


sub single_resource_steps ( $self ) {
	qw(
		_preprocess_request
		_check_http_verb _check_scopes
		_setup_request_headers _check_rate_limiting
		_make_request
		_pre_process_response
		_process_response
		);
	}

sub single_resource ( $self, $verb, %args ) {
	$self->entered_sub;
	$self->logger->debug( sub { "single_resource: Args are " . dumper( \%args ) } );

	my $stash = {
		args          => \%args,
        extras        => {},
        verb          => $verb,
		};

	$self->logger->debug( "single_resource: About to enter foreach" );

	# each step can modify the stash for the next step
	my $result;
	foreach my $step ( $self->single_resource_steps ) {
		$self->logger->debug( "single_resource: Processing single_resource step $step" );
		$result = $self->$step( $stash );
		last if $result->is_error;
		}

	$result->extras( $stash );
	return $result;
	}

sub _validate ( $self, $stash ) {
	$self->entered_sub;
	my $args = $stash->{args};

	return Ghojo::Result->error({
		message     => 'Validation error',
		description => 'The endpoint argument is missing',
		}) unless exists $args->{endpoint};

	my @sets = (
		[ qw(query_params query_profile)       ],
		[ qw(endpoint_params endpoint_profile) ],
		);

	foreach my $set ( @sets ) {
		next unless @$set == grep { exists $args->{$_} } $set->@*;
		my $result = $self->validate_profile( $args->@{ @$set } );
		return $result if $result->is_error;
		}

	$self->endpoint_to_url( $args->@{ qw(endpoint endpoint_params query_params) } );
	}

sub _preprocess_request ( $self, $stash ) {
	$self->entered_sub;
	my $url_result = $self->_validate( $stash );
	return $url_result if $url_result->is_error;

	$stash->{url} = $url_result->values->first;

	$self->logger->debug( "_preprocess_request: URL to single resource is <$stash->{url}>" );

	return Ghojo::Result->success;
	}

sub _check_http_verb ( $self, $stash ) {
	$self->entered_sub;
	state $allowed_verbs = { # with default expected http statuses
		get      => 200,
		post     => 201,
		put      => 200,
		patch    => 200,
		'delete' => 204,
		};

	$stash->{verb} = lc $stash->{verb};
	$self->logger->debug( "_check_http_verb: verb is <$stash->{verb}>" );

	# Check that we have an allowed verb. You shouldn't call this
	# directly in application code, but this check ensures that
	# $verb is something we can handle.
	return Ghojo::Result->error( {
		description => 'Fetching a single resource',
		message     => "Unknown HTTP verb <$stash->{verb}>",
		error_code  => UNKNOWN_HTTP_VERB,
		} ) unless exists $allowed_verbs->{ $stash->{verb} };

	# turn every value for expected_http_status into an array. There
	# are some operations that have more than one HTTP status that
	# signifies normal operation.
	my $args = $stash->{args};
	$args->{expected_http_status} //= $allowed_verbs->{$stash->{verb}};
	$args->{expected_http_status} = [ $args->{expected_http_status} ]
		unless ref $args->{expected_http_status} eq ref [];

	return Ghojo::Result->success;
	}

sub _check_scopes( $self, $stash ) {
	# Before we make the query, check that we have the right scope.
	# When you create a personal access token, you can specify which
	# scopes you want. When we stored the token, we asked for the list
	# of scopes.
	#
	# There are also scopes for teams and orgs
	# this isn't implemented yet
	$self->entered_sub;
	return Ghojo::Result->success unless exists $stash->{args}{required_scopes};

	unless( $self->scopes->satisfies( $stash->{args}{required_scopes}->@* ) ) {
		$self->logger->error(
			sprintf "This operation does not have the required scopes [%s]",
				$stash->{args}{required_scopes}->@*
			);
		$stash->{scopes}{has}      = [ $self->scopes->as_list ];
		$stash->{scopes}{required} = $stash->{args}{required_scopes};
		return Ghojo::Result->error({
			description => 'Fetching a single resource',
			message     => "Operation does not have required scopes",
			});
		}

	return Ghojo::Result->success;
	}

sub _setup_request_headers ( $self, $stash ) {
	$self->entered_sub;
	my %headers;

	# this is the base content-type for the API
	$headers{'Accept'} = $stash->{args}{accepts} // 'application/vnd.github.v3+json';
	$self->logger->debug( "_setup_request_headers: Accept header is: $headers{'Accept'}" );

	# XXX maybe check that this makes sense
	$headers{'Content-type'}  = $stash->{args}{content_type}
		if $stash->{args}{content_type};

	$headers{'X-GitHub-Api-Version'} = $self->api_version;

	$stash->{headers} = \%headers;

	return Ghojo::Result->success;
	}

sub _dump_stash_without_keys ( $self, $stash, $keys = [qw(tx)] ) {
	my %skip_keys = map { $_, 1 } $keys->@*;
	my $caller = (caller(1))[3] =~ s/.*:://r;
	my $dump_hash = ();

	foreach my $key ( keys $stash->%* ) {
		next if exists $skip_keys{$key};
		$dump_hash->{$key} = $stash->{$key};
		}

	$self->logger->debug( sub { "$caller: stash is now:\n" . dumper( $dump_hash ) } );
	}

sub _check_rate_limiting ( $self, $stash ) {
	$self->entered_sub;
	# Not yet implemented
	return Ghojo::Result->success;
	}

sub _make_request ( $self, $stash ) {
	$self->entered_sub;
	my @args = (
		$stash->{url},
		$stash->{headers},
		map {
			exists $stash->{args}{$_}        ?
				($_ => $stash->{args}{$_}) :
				()
			} qw(json form body)
		);

	# XXX: also look in %args for 'json' and 'form'
	my $verb = $stash->{verb};
	$stash->{tx} = $self->ua->$verb( @args );

	return Ghojo::Result->success;
	}

sub _pre_process_response ( $self, $stash ) {
	$self->entered_sub;
	$self->logger->debug( sub { "_pre_process_response: Request was:\n" . dump_request( $stash->{tx} ) } );
	$self->logger->debug( sub { "_pre_process_response: Response was:\n" . dump_response( $stash->{tx} ) } );
	$stash->{query_count} = $self->increment_query_count;
	$self->_update_rate_limit( $stash );
	$self->_process_scopes( $stash );
	$self->_dump_stash_without_keys($stash);
	return Ghojo::Result->success;
	}

sub _update_rate_limit( $self, $stash ) { Ghojo::Result->success }

sub _process_scopes ( $self, $stash ) {
	$self->entered_sub;
	my $scopes = Ghojo::Scopes->extract_scopes_from( $stash->{tx} );

	# reset the scope we are tracking. Maybe they changed?
	$self->init_scopes->add_scopes( $scopes->{has}->as_list );
	$stash->{has_scopes}      = [ $scopes->{has}->as_list ];
	$stash->{required_scopes} = [ eval{ $scopes->{required}->as_list } ];
	}

sub _process_response ( $self, $stash ) {
	$self->entered_sub;
	my $tx = $stash->{tx};
	# check that status is one of the expected statuses
	my $status = $tx->res->code;

	if( grep { $_ == $status } $stash->{args}{expected_http_status}->@* ) {
		my $data = do {
			if( $status == 204 ) {
				[]
				}
			else {
				$stash->{args}{raw_content} ? $tx->res->body : $tx->res->json
				}
			};

		# Can't have raw_content and bless_into at the same time?
		# message body and bless it into the right class
		my $result = $self->_bless_into( $data, $stash );
		return $result if $result->is_error;

		return Ghojo::Result->success( {
			values => [ $data ],
			} )
		}

	$self->logger->debug( sub {
		"Got HTTP status $status while expecting one of "
		. join ', ', $stash->{args}{expected_http_status}->@*
		} );

	# by this time an error has definitely occurred, so figure out
	# what it is
	$self->_classify_error( $stash );
	}

sub _default_data_class ( $self ) { 'Ghojo::Data' }

sub _bless_into ( $self, $data, $stash ) {
	$self->entered_sub;

	$self->_dump_stash_without_keys($stash);

	unless( exists $stash->{args}{bless_into} and defined $stash->{args}{bless_into} ) {
		$self->logger->warn( "_bless_into: Missing bless_into value. Using the default" );
		$stash->{args}{bless_into} = $self->_default_data_class;
		}

	my $package = $stash->{args}{bless_into};
	$self->logger->debug( "_bless_into: package is $package" );
	unless( validate_package( $package ) ) {
		return Ghojo::Result->error( {
			description => "Fetching single resource",
			message     => "Bad package name for bless_into: $package",
			error_code  => BAD_PACKAGE_NAME,
			} );
		}

	$self->logger->debug( "_bless_into: data is " . Mojo::Util::dumper($data) );
	eval "require $package";

	my $object = do {
		if( $package->can('new') ) {
			$package->new($data)
			}
		else {
			bless $data, $package;
			}
		};

	return Ghojo::Result->success( { values => [ $object ] } );
	}

=pod

{"message":"Repository creation failed.",
	"errors":[
		{"resource":"Repository",
		"code":"custom",
		"field":"name",
		"message":"name already exists on this account"
		}],
"documentation_url":"https://docs.github.com/rest/reference/repos#create-a-repository-for-the-authenticated-user"
}

=cut

sub _classify_error ( $self, $stash ) {
	$self->entered_sub;

	my $tx = $stash->{tx};
	my $status = $tx->res->code;

	my $json = eval { $tx->res->json } // {
		message => "Internal JSON because there was an error: $@",
		errors  => [],
		documentation_url => '',
		};

	my $message = join " ",
		$json->{message},
		map { state $n = 0; $_->{message} // '' }
		$json->{errors}->@*;

	if( $status == 404 and $stash->{verb} eq 'get' ) {
		return Ghojo::Result->error( {
			description  => 'Fetching a single resource',
			message      => 'Got a 404 response. Object not found!',
			error_code   => RESOURCE_NOT_FOUND,
			} )
		}

	# XXX: if it's forbidden, what should we do about what we think
	# we good credentials? Check that the token is still valid?
	# try to re-login?
	if( $status == 401 ) {
		$self->logger->debug( "The request requires authentication!" );
		return Ghojo::Result->error({
			message => "The request requires authentication!",
			});
		}

	if( $status == 403 ) {
		$self->logger->debug( "The request was forbidden!" );

		if( $json->{message} =~ /(API rate limit exceeded for \S+)/ ) {
			$message .= $1;
			}

		my @scopes = $self->extract_scopes( $tx );
		my @required_scopes = $self->extract_required_scopes( $tx );

		my $scope_satified = Ghojo::Scopes
			->new( @scopes )
			->satisfies( @required_scopes );


		return Ghojo::Result->error({
			message => $message // "The request was forbidden!",
			});
		}

	if( $status == 415 ) {
		$self->logger->debug( "The request requires additional media types in Accept" );
		return Ghojo::Result->error({
			message => "The request requires additional media types in Accept!",
			});
		}

	if( $status == 422 ) {
		$self->logger->debug( "The request could not be accomodated" );
		return Ghojo::Result->error({
			message => $message // "The request was invalid",
			});
		}

	if( 400 <= $status and $status <= 499 ) {
		$self->logger->debug( "Unhandled 4xx request" );
		return Ghojo::Result->error({
			message => $message // "Unhandled 4xx request",
			});
		}

	return Ghojo::Result->error({
		message => $message // "Unhandled error",
		});
	}

sub paged_resource_steps ( $self ) {
	qw(
		_check_paged_args
		_preprocess_request
		_check_http_verb _check_scopes
		_setup_request_headers
		_make_paged_request
		);
	}

sub _check_paged_args ( $self, $stash ) {
	state %defaults = (
	    args => {
        	limit         => 1000,
        	'sleep'       => 3,
        	callback      => sub { $_[0] },
        	},
        extras        => {},
        verb          => 'get',
        results       => [],
        prev          => undef,
        next          => undef,
        error_count   => 0,
		);

	$self->entered_sub;

	$self->_dump_stash_without_keys($stash);
	$self->logger->debug( "_check_paged_args: args before: " . dumper(\%defaults) );

	my @queue = [ $stash, \%defaults ];
	HASH: while( my $tuple = shift @queue ) {
		my( $sub_stash, $hash ) = $tuple->@*;
		VALUE: foreach my $key ( sort keys $hash->%* ) {
			$self->logger->debug( "_check_paged_args: checking key $key" );
			if( ref $hash->{$key} eq ref {} ) {
				$self->logger->debug( "_check_paged_args: key $key has hash ref value, so queueing" );
				push @queue, [ $sub_stash->{$key}, $hash->{$key} ];
				next VALUE;
				}
			$self->logger->debug( "_check_paged_args: key $key is in the stash: <" . (exists($sub_stash->{$key}) ? 'yes' : 'no') . ">" );
			$self->logger->debug( "_check_paged_args: key $key has stash value <$sub_stash->{$key}>" ) if exists $sub_stash->{$key};
			next if exists $sub_stash->{$key};
			$sub_stash->{$key} = $hash->{$key};
			}
		}

	unless( ref $stash->{args}{callback} eq ref sub {} ) {
		$self->logger->error( "_check_paged_args: Callback argument is not a subroutine reference!" );
		return Ghojo::Result->error({
			message => "The callback entry was not a coderef",
			});
		}

	$self->_dump_stash_without_keys($stash);

	return Ghojo::Result->success;
	}

sub _make_paged_request ( $self, $stash ) {
	state $success = Ghojo::Result->success;
	$self->entered_sub;

	if( $stash->{first_time} ) {
		$self->_turn_on_paging($stash);
		$stash->{first_time} = 0;
		}

	$self->_dump_stash_without_keys($stash);

	# We've either reached our limit or exhausted the results
	if( ! $self->_keep_paging($stash) or $stash->{results}->@* >= $stash->{args}{limit} ) {
		$self->_turn_off_paging( $stash );
		return $success;
		}

	if( $stash->{next} ) {
		$stash->{url} = $stash->{next};
		$stash->{prev} = $stash->{next} = undef;
		}
	else {
		$self->_turn_off_paging($stash);
		}

	$self->logger->trace( "_make_paged_request: Fetching URL $stash->{url}" );

	$self->_make_request( $stash );
	$self->_pre_process_paged_response( $stash );
	$self->_process_paged_response( $stash );

	unless( $stash->{tx}->res->is_success ) {
		$self->_turn_off_paging( $stash );
		return $self->_classify_error( $stash );
		}

	$self->_process_paged_response( $stash );
	}

{
my $key = 'paging';

sub _keep_paging ( $self, $stash ) { $stash->{$key} }

sub _turn_off_paging ( $self, $stash ) {
	$self->entered_sub;
	$stash->{$key} = 0;
	return Ghojo::Result->success;
	}

sub _turn_on_paging ( $self, $stash ) {
	$self->entered_sub;
	$stash->{$key} = 1;
	return Ghojo::Result->success;
	}
}

sub _pre_process_paged_response ( $self, $stash ) {
	$self->entered_sub;
	$self->logger->debug( sub { "Request was:\n" . dump_request( $stash->{tx} ) } );

	$stash->{query_count} = $self->increment_query_count;
	$self->_update_rate_limit( $stash );
	$self->_process_scopes( $stash );

	my $result = $self->_check_http_status( $stash );
	return $result if $result->is_error;

	my $link_header = $self->parse_link_header( $stash->{tx} );
	$stash->{next} = $link_header->{'next'} // '';
	$stash->{last} = $link_header->{'last'} // '';

	return Ghojo::Result->success;
	}

sub _check_http_status ( $self, $stash ) {
	$self->entered_sub;

	my $status   = $stash->{tx}->res->code;
	my $expected = $stash->{args}{expected_http_status};

	my $good_status = grep { $_ == $status } $expected->@*;
	return $self->_classify_error( $stash ) unless $good_status;

	return Ghojo::Result->success;
	}

sub _process_paged_response ( $self, $stash ) {
	$self->entered_sub;
	my $tx   = $stash->{tx};
	my $args = $stash->{args};

	my $result = $self->_check_paged_body( $stash );
	return $result if $result->is_error;

	while ( my $item = shift $stash->{unprocessed_results}->@* ) {
		push $stash->{results}->@*, $stash->{args}{callback}->($item);
		$self->_bless_into( $stash->{results}->@[-1], $stash );
		}

	return Ghojo::Result->success;
	}

# We're expecting JSON, and if we don't get it that's a problem. And
# it can be either an object or array.
sub _check_paged_body ( $self, $stash ) {
	state $success = Ghojo::Result->success;

	$self->entered_sub;

	my $json = eval { $stash->{tx}->res->json };

	$self->logger->debug( "_check_paged_body: res: " . $stash->{tx}->res->to_string );
	$self->logger->debug( "_check_paged_body: JSON: " . dumper($json) );
	$self->logger->debug( sprintf "_check_paged_body: Result JSON ref type is <%s>" , ref($json) );
	$self->logger->debug( sprintf "_check_paged_body: result_key is <%s>", $stash->{args}{result_key} // '' );
	if( ! $json ) {
		my $message = "_check_paged_body: Did not get JSON back";
		$self->logger->error( $message );
		return Ghojo::Result->error({
			message     => $message,
			description => $message
			});
		}
	elsif( ref $json eq ref {} and exists $stash->{args}{result_key} ) {
		return Ghojo::Result->error({
			description => "_check_paged_body: Error fetching paged resource",
			message     => "_check_paged_body: The paged response is a hash but result_key is not set",
			}) unless exists $json->{ $stash->{args}{result_key} };

		$stash->{unprocessed_results} = $json->{ $stash->{args}{result_key} };
		}
	elsif( ref $json eq ref {}  ) {
		$stash->{unprocessed_results} = [ $json ];
		}
	elsif( ref $json ) {
		$stash->{unprocessed_results} = $json;
		}

	$self->_dump_stash_without_keys($stash);

	return $success;
	}

# this is blocking, but there's not another way around it
# you don't know the next one until you see the response
sub get_paged_resources ( $self, %args ) {
	$self->entered_sub;
	$self->logger->debug( sub { "get_paged_resources args are " . dumper( \%args ) } );

	my $stash = { args => \%args };
	$stash->{args}{sleep} //= 1;
	$stash->{first_time} = 1;
	$self->_dump_stash_without_keys($stash);

	# each step can modify the stash for the next step
	my $result;
	foreach my $step ( $self->paged_resource_steps ) {
		$self->logger->trace( "Processing step <$step>" );
		$result = $self->$step( $stash );
		return $result if $result->is_error;
		redo if $stash->{redo}
		}

	Ghojo::Result->success({
		values => $stash->{results},
		});
	}

# <https://api.github.com/repositories?since=367>; rel="next", <https://api.github.com/repositories{?since}>; rel="first"';
sub parse_link_header ( $self, $tx ) {
	$self->entered_sub;
	my $link_header = $tx->res->headers->header( 'Link' );

	return {} unless $link_header;

	my @parts = $link_header =~ m{
		<(.*?)>; \s+ rel="(.*?)"
		}xg;

	my %hash = reverse @parts;
	$self->logger->trace( sprintf "next is <%s>", $hash{'next'} // '' );
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

Github uses Content-Type values to do or enable various things.

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

=head2 Deprecated stuff

=over 4

=item * set_paged_get_sleep_time

=item * paged_get_sleep_time

=item * set_paged_get_results_limit

=item * paged_get_results_limit

=item * paged_get

=cut

sub set_paged_get_sleep_time   ( $self, @ )  { $self->logdie( "paged_get is deprecated" ) }

sub paged_get_sleep_time        ( $self )    { $self->logdie( "paged_get is deprecated" ) }

sub set_paged_get_results_limit ( $self, $ ) { $self->logdie( "paged_get is deprecated" ) }

sub paged_get_results_limit     ( $self )    { $self->logdie( "paged_get is deprecated" ) }

sub paged_get                   ( $self, @ ) { $self->logdie( "paged_get is deprecated" ) }

=back

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/ghojo

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2. A F<LICENSE> file should have accompanied
this distribution.

=cut

__PACKAGE__
