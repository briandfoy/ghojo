use v5.26;
use experimental qw(signatures);

use Ghojo;

use MIME::Base64;
use Mojo::Util qw(dumper);

my( $owner, $repo ) = split m|/|, $ARGV[0];
unless( $owner and $repo ) {
	die "Need owner and repo arguments\n";
	}

my $ghojo = Ghojo->new({ token => $ENV{GHOJO_TOKEN} });
if( $ghojo->is_error ) {
	say $ghojo->short_summary;
	exit;
	}

say "----- LIST SECRET";
my $result = $ghojo->list_environments( $owner, $repo );
say "Environments";
foreach my $environment ( $result->values->@* ) {
	say sprintf "\t%s:", $environment->name;
	list_secrets($owner, $repo, $environment->name);
	}

say '----- CREATE AGAIN';

my $env_result = $ghojo->create_environment( $owner, $repo, 'release' );
say dumper( $env_result );
exit;

say "----- CREATE SECRET";
my $name = "NEW_SECRET_$$";
my $value = "foo bar";
my $environment_name = 'release';
my $created_result = $ghojo->create_environment_secret( $owner, $repo, $environment_name, $name, $value );
if( $created_result->is_error ) {
	say $created_result->short_summary;
	exit;
	}
else {
	say "create succeeded";
	}

say "----- LIST SECRET AFTER CREATE";
my $result = $ghojo->list_environments( $owner, $repo );
say "Environments";
foreach my $environment ( $result->values->@* ) {
	say sprintf "\t%s:", $environment->name;
	list_secrets($owner, $repo, $environment->name);
	}

say "Enter to continue....";
<STDIN>;

say "----- DELETE SUBJECT";
my $delete_result = $ghojo->delete_environment_secret( $owner, $repo, $environment_name, $name );
if( $delete_result->is_error ) {
	say $delete_result->short_summary;
	say "delete not found";
	}
else {
	say "delete succeeded";
	}



exit;

####################################################################################

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



say "----- GET SECRET";
my $secret = $ghojo->get_repository_secret( $owner, $repo, $name );
if( $secret->is_error ) {
	say $secret->short_summary;
	exit;
	}
else {
	say "get succeeded";
	}


sub list_secrets ( $owner, $repo, $environment ) {
	$environment = $environment->name if $environment->can('name');
	my $secret_list = $ghojo->list_environment_secrets( $owner, $repo, $environment );
	if( $secret_list->is_error ) {
		say $secret_list->short_summary;
		exit;
		}
	else {
		foreach my $secret ( $secret_list->values->@* ) {
			say dumper($secret);
			say sprintf "\t\t%s %s %s\n", map { $secret->$_() } qw(name created_at updated_at);
			}
		}
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
