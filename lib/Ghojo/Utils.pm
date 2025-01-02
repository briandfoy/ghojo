use v5.26;

package Ghojo::Utils;
use experimental qw(signatures);

use Carp qw(carp);
use Exporter   qw(import);
use Mojo::Util qw(b64_encode dumper trim);
use Mojo::JSON qw(decode_json);
use Storable   qw(dclone);

our @EXPORT_OK = qw(
	dump_request dump_response
	dclone
	decode_json
	b64_encode dumper trim
	validate_package
	);

our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
	);

sub dump_request ( $tx ) {
	carp "Did not get a transaction!" unless ref $tx;
	my $string = $tx->req->to_string;
	$string =~ s/Authorization:\s+token\s+...\K.*/***/;
	$string =~ s/Authorization:\s+basic\s+\K.*/***/r;
	}

sub dump_response ( $tx ) {
	carp "Did not get a transaction!" unless ref $tx;
	my $start_line = join ' ', $tx->res->code, 'HTTP/1.1';
	$start_line . "\n" . $tx->res->headers->to_string
	}

sub validate_package ( $package ) {
	$package =~ m/\A [A-Za-z][A-Za-z0..9_]* (::[A-Za-z][A-Za-z0..9_]*)* \z/x
	}

__PACKAGE__;
