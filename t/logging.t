#!perl
use v5.24.0;

use Test::More 1;
use Data::Dumper;
use File::Spec::Functions;
use Mojo::File;
use Mojo::Loader qw{data_section};
use Ghojo;

## remove any existing log files
unlink glob 't/*.log';

## test passing the conf as a reference to new
subtest scalar_reference => sub {
	my $section = 'new-arg.conf';
	my $conf = data_section( __PACKAGE__, $section );
	ok( defined $conf, "Log4perl conf for $section is defined" );

	my( $filename ) = $conf =~ /Logfile\.filename \s* = \s* (\S+)/x;
	unlink $filename;
	ok( ! -e $filename, "logfile [$filename] does not exist yet for $section" );

	my $ghojo = Ghojo->new( { logging_conf => \$conf } );
	isa_ok( $ghojo, 'Ghojo' );

	ok( -e $filename, "logfile [$filename] created for $section" );
	unlink $filename
		or diag( "Could not remove $filename created by testing for $section" );
	};

## replace in previous conf string, write to file and
## test passing a filename to new
subtest filename => sub {
	my $conf = data_section( __PACKAGE__, 'new-arg.conf' );
	my $file_conf_data = $conf =~ s{t/new}{t/file}r;
	my( $filename ) = $file_conf_data =~ /Logfile.filename \s* = \s* (\S+)/x;

	unlink $filename;
	ok( ! -e $filename, "logfile [$filename] does not exist yet for file-conf" );

	my $conf_filename = catfile( qw(t log4perl.conf) );
	Mojo::File->new( $conf_filename )->spurt( $file_conf_data );
	ok( -e $conf_filename, "log config [$conf_filename] is there" );

	my $ghojo = Ghojo->new( { logging_conf => $conf_filename } );
	isa_ok( $ghojo, 'Ghojo' );

	ok( -e catfile( qw(t file.log) ), 'logfile created' );
	unlink $filename
		or diag( "Could not remove $filename created by testing for file-conf" );
	};

## use a subclassed, redefined logging_conf()
subtest subclass => sub {

	package Test::Ghojo::Log {
		use Mojo::Base qw{Ghojo};
		use Mojo::Loader qw{data_section};

		sub logging_conf {
			return \ data_section( 'main', 'subclass.conf' );
			};
		}

	my $filename = catfile( qw(t subclass.log ) );
	unlink $filename;
	ok( ! -e $filename, "logfile [$filename] does not exist yet for subclass" );

	my $ghojo = Test::Ghojo::Log->new;
	isa_ok( $ghojo, 'Ghojo' );

	ok( -e $filename, "logfile ($filename) created from subclass" );
	unlink $filename
		or diag( "Could not remove $filename created by testing for subclass" );
	};

done_testing();

__DATA__
@@ new-arg.conf
log4perl.rootLogger = TRACE, Logfile

log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = t/new.log
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = [%r] %F %L %m%n

log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 1
log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout

@@ subclass.conf
log4perl.rootLogger = TRACE, Logfile

log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = t/subclass.log
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = [%r] %F %L %m%n

log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 1
log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout
