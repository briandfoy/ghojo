#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use experimental qw(signatures);

use lib qw(lib);

use Ghojo;
use Ghojo::Constants;
use subs qw(FILE_NOT_FOUND);

use Mojo::Util qw(dumper);

my $ghojo = Ghojo->new;

# the third parameter is a boolean for HTMLized contents
my $result = $ghojo->get_contents(
	'briandfoy',
	'ghojo',
	$ARGV[0] // 'Makefile.PL',
	{
	  'ref'     => $ARGV[1] // 'master',
	}
	);

if( $result->is_success ) {
	my $file = $result->single_value->content;
	print $file;
	}
else {
	if( $result->error_code eq RESOURCE_NOT_FOUND ) {
		say "Object not found";
		}
	else {
		say "Some unspecified error";
		}
	}
