#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Ghojo;

my $emoji_code = shift;
die "Specify an emoji code!\n" unless defined $emoji_code;

my $ghojo = Ghojo->new;

my $result = $ghojo->get_emojis;
if( $result->is_success ) {
	say "Is this from the cache? " . $result->extras->{cache_hit} ? 'Yes' : 'No';
	if( my $url =  $ghojo->get_emoji_image_for( $emoji_code ) ) {
		say "Image for $emoji_code is " . $url;
		}
	}
