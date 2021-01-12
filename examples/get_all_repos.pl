#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

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
my $summary_file = 'github_repos_summary.txt';
my $user_file    = 'github_users.txt';

make_pid_file( $pid_file );


my $error = 0;
while( $error < 500 ) {
	my $ghojo =  go_go_ghojo();
	my $logger = $ghojo->logger;

	my $result = $ghojo->all_public_repos(
		make_callback( $repo_file ),
		{ since   => get_last_id( $repo_file ) },  # query args
		{ 'sleep' => sleep_time(), limit => request_limit() } # extra method args
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

	$logger->info( 'Sleeping for an hour' );
	sleep 3600;
	}

sub sleep_time ()    { $ENV{GHOJO_SLEEP_SECONDS} // 0 }
sub request_limit () { $ENV{GHOJO_REQUEST_LIMIT} // 50_000 }

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

sub make_callback ( $repo_file ) {
	open my $list_fh, '>>:utf8', $repo_file;
	open my $user_fh, '>>:utf8', $user_file;
	open my $repo_fh, '>>:utf8', $summary_file;

	my $callback = sub ( $item, $tx ) {
		state $count = 0;

		my $owner = $item->{owner};

		my $string = join "\t",
			$item->{'id'},
			$item->{'fork'},
			$owner->{login},
			$item->{name},
			$item->{private},
			$item->{description},
			;

		say { $repo_fh } $string;
		say { $user_fh } join "\t",
			$owner->{id},
			$owner->{login},
			$item->{gravatar_id},
			;

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
	my $last_line = get_last_line( $summary_file );
	say "Last line is > $last_line";
	my $since = ( split /\s+/, $last_line )[0] // 0;
	say "Last repo id was>  $since";
	return $since;
	}

sub get_last_line ( $repo_file ) {
	use Encode;
	use Fcntl;

	open my $fh, '<:raw', $repo_file or die "Could not open $repo_file: $!";
	seek $fh, -5000, Fcntl::SEEK_END;
	read $fh, my $raw_octets, 5000 or return '';  # these are raw octets

	# We might have read in the middle of a UTF-8 character
	# FB_DEFAULT will replace the incomplete bits with the
	# substitution character 0xfffd
	my $utf8_text = Encode::decode('UTF-8', $raw_octets, Encode::FB_DEFAULT);
	chomp $utf8_text;

	$utf8_text =~ s/.*\n//sr;
	}
