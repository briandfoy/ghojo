#!perl
use v5.24;
use experimental qw(signatures);

=head1 NAME

github_rate_monitor.pl -

=head1 SYNOPSIS

	$ github_rate_monitor.pl [POLL_INTERVAL]

	14:14  4999/5000  3579  -0.000   0.000
	14:15  4999/5000  3519  -0.000   0.000

=head1 DESCRIPTION

The GitHub API has several rate limits. There's a very low limit for
the unauthenticated API and a higher one for the authemticated API. However,
they also limit the requests coming from a single IP address. This one
monitors the "core" rate limit.

Poll the C</rate_limit> GitHub API endpoint every POLL_INTERVAL seconds
(or 60 seconds by default). The output columns report:

=over 4

=item * time in HH::MM

=item * remaining requests as a fraction of the limit

=item * seconds left until the limit resets

=item * the speed of requests, per second

=item * the acceleration of requests, per second per second

=back

The rate limit is described in L<https://developer.github.com/v3/#rate-limiting>.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright © 2017 brian d foy, C<< <bdfoy@cpan.org> >>

=head1 LICENSE

You can use this code under the Artistic License 2.0.

=cut

use FindBin;

# This assumes that you are working in the repo at the top level:
#	perl -Ilib examples/rate_monitor.pl
use lib (
	"$FindBin::Bin/../lib",
	"$FindBin::Bin/../examples",
	);

use Data::Dumper;

BEGIN { require 'common_things.pl' }

$SIG{INT} = sub { exit };

# This comes from common_things.pl. It logs in with the test
# user. You can make your own Ghojo object here if you like.
my $ghojo = go_go_ghojo();

# The number of seconds between rate requests.
my $interval = $ARGV[0] // 60;

# I know this number because I know this number. It's not explicitly
# documented anywhere. The window resets hourly
my $RESET_TIME = 3600;

while( 1 ) {
	state $remaining_previous_time          = 0;
	state $requests_remaining_previous_time = 0;
	state $speed_previous_time              = 0;

	next if time % $interval;

	my $rate = $ghojo->get_fresh_rate_limit;

	my $core = $rate->{resources}{core};

	my $time_to_reset = $core->{'reset'} - time;

	my $requests_in_previous_interval = do {
		# remaining reset during the interval
		if( $core->{remaining} > $remaining_previous_time ) {
			my $requests_in_this_window = $core->{limit} - $core->{remaining};

			# the total time in the current and previous windows
			# should be the interval time
			my $time_in_this_window = $RESET_TIME - $core->{'reset'};
			my $time_in_previous_window = $interval - $time_in_this_window;

			# guess that the rate is uniform throughout the window.
			# figure out the requests in the previous window by the
			# proportion in this window.
			my $requests_in_previous_window = $requests_in_this_window *
				( $time_in_previous_window / $time_in_this_window )
				;

			$requests_in_previous_window + $requests_in_this_window
			}
		# remaining did not reset
		else {
			$remaining_previous_time - $core->{remaining};
			}
		};

	$requests_remaining_previous_time = $core->{remaining};

	my $speed =   $requests_in_previous_interval  / $interval;

	my $accel = ( $speed_previous_time - $speed ) / $interval;
	$speed_previous_time = $speed;

	my( $hour, $minute ) = ( localtime )[ 2, 1 ];

	printf "%02d:%02d  %4d/%4d  %4d  %6.3f  %6.3f\n",
		$hour, $minute,
		$core->{remaining},
		$core->{limit},
		$time_to_reset,
		$speed,
		$accel
		;

	sleep 1;
	}


