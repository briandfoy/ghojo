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

add_label_to_every_repo.pl - Add a label to all open issues in GitHub

=head1 SYNOPSIS

	# run it out of the cloned repo. It's not ready for installation
	% cpan Term::ReadKey Log::Log4perl Mojolicious
	% perl5.24 examples/add_label_to_every_repo.pl github_username
	Type in your secret password:  ...

=head1 DESCRIPTION

October is time for Hacktoberfest (https://hacktoberfest.digitalocean.com),
a partnership between DigitalOcean and GitHub. Create four pull requests
against issues with the label "Hacktoberfest" and they will send you
a t-shirt.

=over 4

=item 1. Register your GitHub account at https://hacktoberfest.digitalocean.com/sign_up/register

=item 2. Make four pull requests between Oct 1 and Oct 31

=item 3. Success!

=back

That's it.

This program goes through all of the GitHub repositories owned by you.
It adds the GitHub label to each repo, and applies that label to every
open issue. You must be the owner of the repository.

Before you get wacky with this, I suggest you try it against a burner
account and a repo you don't care about. I've run it against mine.

If you like playing around with this tool I threw together, you can
make pull requests against its repo. I've labeled all of those as
Hacktoberfest! If you want to fix something that's not an issue,
create the issue and I'll label it. After I label it, send your pull
request! I've made some simple issues that almost anyone should be
able to handle.

If you like these sorts of tools and want me to help you at your business,
I'd love to hack on this a lot more. Let me know how I can help you make
GitHub tools (and, I'd like to try this against GitHub Enterprise).

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


my $hash = {
	username => username(),
	password => password(),
	};

my $label_name = 'Hacktoberfest';

my $ghojo = Ghojo->new( $hash );
$ghojo->logger->level( log_level() );

my $callback = sub ( $item ) {
	unless( ref $item eq ref {} ) {
		$ghojo->logger->error( "Not a hashref!" );
		return;
		}
	$ghojo->logger->info( $item->{full_name} );

	my( $user, $repo ) = split m{/}, $item->{full_name};

	my $owner = $item->{owner}{login};
	return unless $ghojo->logged_in_user eq $owner;

	say $item->{full_name};
	my $repo = $ghojo->get_repo_object( $owner, $repo );
	unless( $repo ) {
		$ghojo->logger->error( "Problem creating repo thingy" );
		return;
		}

	# get the labels for that repo
	my %labels = map { $_->@{ qw(name color) } } $repo->labels->@*;

	unless( exists $labels{$label_name} ) {
		my $rc = $repo->create_label( $label_name, 'ff5500' );
		say "\tCreated $label_name label" if $rc;
		}

	my $callback = sub ( $item ) {
		my( $number, $title ) = $item->@{ qw(number title) };
		say "\t$number: $title";
		$repo->add_labels_to_issue( $number, $label_name );
		return $item;
		};

	my $issues = $repo->issues( $callback );
	return 1;
	};

$ghojo->repos( $callback, {} );

