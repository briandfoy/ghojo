#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Mojo::Util qw(dumper);

use Ghojo;
use Data::Dumper;

my $ghojo = Ghojo->new;

my $result = $ghojo->get_readme( 'briandfoy', 'ghojo' );
if( $result->is_success ) {
	my $file = $result->single_value->contents;
	print $file;
	}

my $result = $ghojo->get_contents( 'briandfoy', 'ghojo', 'Makefile.PL' );
if( $result->is_success ) {
	my $file = $result->single_value->contents;
	print $file;
	}


my $result = $ghojo->get_contents( 'briandfoy', 'ghojo', 'not-there' );
if( $result->is_success ) {
	my $file = $result->single_value->contents;
	print $file;
	}
else {
	delete $result->{extras};
	say Dumper( $result );
	}
