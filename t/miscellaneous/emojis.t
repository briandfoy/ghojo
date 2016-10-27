use v5.24;

use Test::More 1;

use Mojo::Util qw( dumper );

my $class  = 'Ghojo';
my $method = 'get_emojis';

use_ok( $class );

my $ghojo = Ghojo->new;
isa_ok( $ghojo, $class );
isa_ok( $ghojo, 'Ghojo::PublicUser' );
can_ok( $ghojo, $method );

my $result = $ghojo->$method();
isa_ok( $result, 'Ghojo::Result' );
isa_ok( $result->values->first, 'Ghojo::Data::Emojis' );

can_ok( $ghojo, 'emoji_cache' );
isa_ok( $ghojo->emoji_cache, ref {} );
ok( $ghojo->emoji_cache->%*, "There are some hash keys in the cache" );

subtest checkered_flag => sub {
	my $code = 'checkered_flag';

	like( $ghojo->get_emoji_image_for( $code ), qr/1f3c1\.png/,
		"There's a emoji for <$code> (without colons)" );
	like( $ghojo->get_emoji_image_for( ":$code:" ), qr/1f3c1\.png/,
		"There's a emoji for <:$code:> (with colons)" );

	is( $ghojo->get_emoji_char_for( $code ) , chr( 0x1f3c1 ),
		"get_emoji_char_for returns the right char for <$code>" );
	};

subtest bite_my_shiny_ass => sub {
	my $code = 'bite_my_shiny_ass';

	ok( ! defined $ghojo->get_emoji_image_for( $code ),
		"There's no emoji for <$code>" );

	ok( ! defined $ghojo->get_emoji_char_for( $code ),
		"get_emoji_char_for returns undef for <$code>" );
	};

done_testing();
