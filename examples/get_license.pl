#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(lib);

use Mojo::Util qw(dumper);

use Ghojo;

my $license_name = shift;
die "Specify a license name!\n" unless defined $license_name;

my $ghojo = Ghojo->new;

my $result = $ghojo->get_gitignore_template_names;
if( $result->is_success ) {
	say "Templates are:\n\t", join "\n\t", $result->values->first->@*;
	}

if( $ghojo->gitignore_template_name_exists( $template_name ) ) {
	say ">>>There's a template for <$template_name>";
	my $result = $ghojo->get_gitignore_template( $template_name );
	if( $result->is_success ) {
		say $result->values->first->{source};
		}
	else {
		say "Could not fetch template for <$template_name>";
		}
	}
else {
	say ">>>There's no template for <$template_name>";
	exit 1;
	}
