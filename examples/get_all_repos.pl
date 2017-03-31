#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(
	/Users/brian/Dropbox/Dev/Ghojo/lib
	/Users/brian/Dropbox/Dev/Ghojo/examples
	);

use Data::Dumper;
use File::Basename        qw(basename);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile);
use IO::Interactive       qw(interactive);
use JSON::XS              qw(encode_json); # This should be Mojo::JSON

select interactive();

BEGIN { require 'common_things.pl' }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


my $program_name = basename( $0 );
exit_if_already_running( $program_name );


my $pid_file     = "$program_name-$$.pid";
my $repo_file    = 'github_repos.txt';

make_pid_file( $pid_file );


my $error = 0;
while( $error < 500 ) {
	my $ghojo =  go_go_ghojo();
	my $logger = $ghojo->logger;

	my $result = $ghojo->all_public_repos(
		make_callback( $repo_file ),
		{ since   => get_last_id( $repo_file ) },  # query args
		{ 'sleep' => 1, limit => 5_000_000     } # extra method args
		);
	if( $result->is_error ) {
		$logger->error( "Encountered an error: " . $result->message );
		say $result->extras->{tx}->req->to_string;
		say $result->extras->{tx}->res->to_string;

		my $rate_result = $ghojo->get_fresh_rate_limit;
		my $remaining   = $rate_result->{resources}{core}{remaining};
		my $reset       = $rate_result->{resources}{core}{'reset'};
		if( $remaining <= 100 ) {
			$logger->info( "Rate remaining is $remaining, resets at $reset" );
			my $sleep = $reset - time;
			$logger->info( "Sleeping for $sleep" );
			sleep $sleep + 60;
			}
		else {
			sleep 60 * (++$error % 10);
			}
		}
	}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub make_pid_file ( $pid_file ) {
	END { unlink $pid_file }
	$SIG{INT} = sub {
		say "Caught INT. Exiting";
		unlink $pid_file;
		exit 1;
		};

	open my $fh, '>:utf8', $pid_file;
	print {$fh} time;
	close $fh;
	}

sub go_go_ghojo () {
	state $rc = require Ghojo;
	$ENV{GHOJO_LOG_LEVEL} = log_level();

	# we log in because there's a higher API rate limit.
	my $hash = {
		username     => username(),
		password     => password(),
		authenticate => 0,
		};
	my $ghojo = Ghojo->new( $hash );
	$ghojo->logger->debug( "GHOJO_LOG_LEVEL is " . log_level() );

	$ghojo->logger->trace( "Checking Login" );
	if( $ghojo->is_error ) {
		$ghojo->logger->error( "Error logging in! " . $ghojo->message );
		my @keys = keys $ghojo->extras->%*;
		$ghojo->logger->error( "Exiting!" );
		}
	$ghojo->logger->trace( "Login was not an error" );

	$ghojo;
	}

sub make_callback ( $repo_file ) {
	open my $list_fh, '>>:utf8', $repo_file;

	my $callback = sub ( $item, $tx ) {
		state $count = 0;

		say join "\t", $item->{id}, $item->{full_name};
		say { $list_fh } join "\t", $item->{id}, $item->{full_name};

		my $user = $item->{owner}{login};
		my $path = catfile(
			substr( $user, 0, 1 ),
			substr( $user, 0, 2 ),
			$user);
		make_path $path unless -d $path;

		my $file = catfile( $path, $item->{name} );
		my %hash = %$item;
		open my $fh, '>:utf8', $file or
			warn "Could not open $file: $!";
		print { $fh } encode_json( \%hash );
		close $fh;

		return $count++;
		};
	}

sub exit_if_already_running ( $program_name ) {
	my @files = glob "$program_name-*.pid";
	say "Found pid files> @files";

	my $running = 0;
	my @running = ();
	foreach my $file ( @files ) {
		my( $pid ) = $file =~ /(\d+)/;
		say "Found pid $pid";

		my $rc = kill 0, $pid;
		$running += $rc;
		push @running, $pid;
		unlink $file unless $rc; # remove pid file if the process isn't there
		}

	if( $running ) {
		say "Exiting: there are processes still running: @running";
		exit;
		}
	}

sub get_last_id ( $repo_file ) {
	# Find the last ID that we have in the file. That's our starting
	# point for the next batch of things.
	my $last_line = get_last_line( $repo_file );
	my $since = ( split /\s+/, $last_line )[0] // 0;
	say "Last repo id was>  $since";
	return $since;
	}

sub get_last_line ( $repo_file ) {
	use Encode;
	use Fcntl;

	open my $fh, '<:raw', $repo_file or die "Could not open $repo_file: $!";
	seek $fh, -500, Fcntl::SEEK_END;
	read $fh, my $raw_octets, 500 or die "Could not read: $!";  # these are raw octets

	# We might have read in the middle of a UTF-8 character
	# FB_DEFAULT will replace the incomplete bits with the
	# substitution character 0xfffd
	my $utf8_text = Encode::decode('UTF-8', $raw_octets, Encode::FB_DEFAULT);
	chomp $utf8_text;

	$utf8_text =~ s/.*\n//sr;
	}
