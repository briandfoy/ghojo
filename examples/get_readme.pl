#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;
use Mojo::Util qw(dumper);

my $ghojo = Ghojo->new;

# the third parameter is a boolean for HTMLized contents
my $result = $ghojo->get_readme(
	'briandfoy',
	'ghojo',
	{
	  'as_html' => !! $ARGV[0],
	  'ref'     => $ARGV[1] // 'master',
	}
	);

if( $result->is_success ) {
	my $file = $result->single_value;
	print $file;
	}
else {
	say "There was an error!";
	}
