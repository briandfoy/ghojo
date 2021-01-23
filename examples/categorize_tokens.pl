#!perl
use v5.10;

use lib qw(lib);

use File::Path qw(make_path);
use File::Spec::Functions;

use Ghojo;

my $dir_path = catfile( $ENV{HOME}, '.github' );
make_path( $dir_path );

while( <> ) {
	chomp;
	my $t = substr $_, 0, 5;
	my $ghojo = Ghojo->new({ token => $_ });
	if( $ghojo->is_error ) {
		warn "Token <$t> had a problem\n";
		next;
		}

	say "<$t> scopes: ", join ' ', sort $ghojo->scopes->as_list;

	my $j = join '-', $t, sort $ghojo->scopes->as_list;
	$j =~ s/:/#/g;

	open my $fh, '>:encoding(UTF-8)', catfile( $dir_path, $j );
	say { $fh } $_;
	close my $fh;
	}
