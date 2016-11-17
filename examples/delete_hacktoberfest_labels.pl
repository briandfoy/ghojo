#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

BEGIN{ require 'common_things.pl' }

use Ghojo;

=head1 NAME

delete_hacktoberfest_labels.pl - Remove the Hacktoberfest label from all repos

=head1 SYNOPSIS

	# run it out of the cloned repo. It's not ready for installation
	% cpan Term::ReadKey Log::Log4perl Mojolicious
	% perl5.24 examples/delete_hacktoberfest_labels.pl github_username
	Type in your secret password:  ...

=head1 DESCRIPTION

October I<was> time for Hacktoberfest
(https://hacktoberfest.digitalocean.com), a partnership between
DigitalOcean and GitHub. Create four pull requests against issues with
the label "Hacktoberfest" and they will send you a t-shirt. But, it's
over now, so remove all of those labels.

This program goes through all of the GitHub repositories owned by you.
It removes the Hacktoberfest label from each repo. You must be the
owner of the repository.

If you like these sorts of tools and want me to help you at your
business, I'd love to hack on this a lot more. Let me know how I can
help you make GitHub tools (and, I'd like to try this against GitHub
Enterprise).

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/ghojo.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

die "Specify a username as the only argument!" unless defined $ARGV[0];

my $hash = {
	username => $ARGV[0],
	password => password(),
	};

my $label_name = 'Hacktoberfest';

my $ghojo = Ghojo->new( $hash );
$ghojo->logger->level( log_level() );

my $callback = sub ( $item, @ ) {
	unless( ref $item eq ref {} ) {
		$ghojo->logger->error( "Not a hashref!" );
		return;
		}
	$ghojo->logger->info( $item->{full_name} );

	my( $owner, $repo ) = split m{/}, $item->{full_name};

	$ghojo->delete_label( $owner, $repo, $label_name );

	return 1;
	};

$ghojo->repos( $callback );

