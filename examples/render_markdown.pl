#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Mojo::Util qw(dumper);

use Ghojo;

my $markdown = <<'MARKDOWN';
# Planet Express

## The crew

* Fry
* Bender
* Leela
MARKDOWN

my $ghojo = Ghojo->new;

my $result = $ghojo->render_markdown( $markdown );
if( $result->is_success ) {
	say "Rendered contextual markdown:";
	say $result->values->first;
	}
else {
	say "There was an error! " . $result->message;
	}

my $raw_result = $ghojo->render_raw_markdown( $markdown );
say dumper( $raw_result );
if( $raw_result->is_success ) {
	say "Rendered raw markdown:";
	say $raw_result->values->first;
	}
else {
	say "There was an error! " . $raw_result->message;
	}
