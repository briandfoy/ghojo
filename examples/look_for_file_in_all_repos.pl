#!/Users/brian/bin/perls/perl5.24.0
use v5.24;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use lib qw(
	/Users/brian/Dropbox/Dev/Ghojo/lib
	/Users/brian/Dropbox/Dev/Ghojo/examples
	);

use File::Basename        qw(basename);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile);
use IO::Interactive       qw(interactive);
use JSON::XS              qw(encode_json); # This should be Mojo::JSON

select interactive();

BEGIN { require 'common_things.pl' }

