use v5.24;

use Text::CSV_XS qw( csv );

my $filename = $ARGV[0];

my $csv = Text::CSV_XS->new;
open my $fh, "<:utf8", $filename or die "$filename: $!";

my @headers = (
	'Category',
	'Subcategory',
	'Deprecated',
	'Preview',
	'Reactions',
	'Raw',
	'Cached',
	'Scopes',
	'SNI',
	'Description',
	'Verb',
	'Endpoint',
	'Expected Status Code',
	'Array of arrays',
	'Array of hashrefs, paged',
	'Hash ref',
	'Empty body',
	'Array of strings',
	'Authenticated',
	'Location',
	'Sends array',
	'params',
	'content-type'
	);

my %params;
while( my $row = $csv->getline($fh) ) {
	my %hash = map { $headers[$_] => $row->[$_] } 0 .. $#headers;
	next unless $hash{Endpoint};
	my @params = $hash{Endpoint} =~ m{/:([^/?]+)}g;
	$params{$_}++ for @params;
	print <<"HERE";
$hash{Verb} $hash{Endpoint}
HERE
	}
close $fh;

foreach my $key ( sort { $params{$b} <=> $params{$a} } keys %params ) {
	printf "%3d %s\n", $params{$key}, $key;
	}
