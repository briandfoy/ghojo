#!/Users/brian/bin/perls/perl5.24.0
use v5.24;

use lib qw(lib);
use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Ghojo;

say Ghojo->new->get_user( shift )->{email} || "(No email found, or it is private)";
