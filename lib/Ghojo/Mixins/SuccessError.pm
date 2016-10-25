use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

sub is_success { 1 }
sub is_error   { 0 }

__PACKAGE__
