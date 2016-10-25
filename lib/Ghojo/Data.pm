use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

package Ghojo::Data;
use parent qw( Hash::AsObject ); # as a quick fix. I'd rather lose the dependency

use Ghojo::Mixins::SuccessError;

# until we need to build out these classes
my @classes = qw( SSHKey GPGKey UserRecord Email Grant );
foreach my $class ( @classes ) {
	no strict 'refs';
	@{ "Ghojo::Data::$class\::ISA" } = __PACKAGE__;
	}

__PACKAGE__
