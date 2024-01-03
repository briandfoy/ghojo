use v5.10;
use strict;

use Ghojo;

use MIME::Base64;
use Mojo::Util qw(dumper);

my( $owner, $repo ) = split m|/|, $ARGV[0];

my $ghojo = Ghojo->new({ token => $ENV{GHOJO_TOKEN} });
if( $ghojo->is_error ) {
	say $ghojo->short_summary;
	exit;
	}

my $public_key_encoded = $ghojo->get_repository_public_key( $owner, $repo );
my $key_base64 = $public_key_encoded->values->[0]->{key};

my $name = 'TEST_SECRET';
my $value = 'Kangaroo';

say "----- DELETE SUBJECT";
my $delete_result = $ghojo->delete_repository_secret( $owner, $repo, $name );
if( $delete_result->is_error ) {
	say $delete_result->short_summary;
	say "delete not found";
	}
else {
	say "delete succeeded";
	}

say "----- CREATE SECRET";
my $created_result = $ghojo->create_repository_secret( $owner, $repo, $name, $value );
if( $created_result->is_error ) {
	say $created_result->short_summary;
	exit;
	}
else {
	say "create succeeded";
	}

say "----- GET SECRET";
my $secret = $ghojo->get_repository_secret( $owner, $repo, $name );
if( $secret->is_error ) {
	say $secret->short_summary;
	exit;
	}
else {
	say "get succeeded";
	}

say "----- LIST SECRETS";
my $secret_list = $ghojo->list_repository_secrets( $owner, $repo );
if( $secret_list->is_error ) {
	say $secret_list->short_summary;
	exit;
	}
else {
	say "list succeeded";
	say dumper($secret_list);
	say $secret_list->values->map( sub { dumper($_) } )->join("\n");
	}

__END__

 ret = crypto_box_easy(c + crypto_box_PUBLICKEYBYTES, m, mlen,
                          nonce, pk, esk);


$ perl -Ilib examples/get_secret_public_key.pl briandfoy/fafo
bless( [
  bless( {
    "key" => "dEoOguJKeKKpWY9Jc487aX9z3me7S2hZiTruw77isFY=",
    "key_id" => "568250167242549743"
  }, 'Ghojo::Data::SecretPublicKey' )
], 'Mojo::Collection' )

Hello Perl

PC0T6ExrjhvnzmWo3kLSvuSD50JKdwbYhefzaLKxZw9JWq8jk9HK1ZNmOp5sAV0lbw5Sd0K70C/dOw==
