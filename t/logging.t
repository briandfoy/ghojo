#!perl
package Test::Ghojo::Log;

use Mojo::Base qw{Ghojo};
use Mojo::Loader qw{data_section};

sub logging_conf {
  return \ data_section( 'main', 'subclass.conf' );
};

package main;

use Test::More 0.95;
use Data::Dumper;
use Mojo::Loader qw{data_section};
use Mojo::Util qw{spurt};
use Ghojo;

my $ghojo;

## remove any existing log files
unlink glob 't/*.log';

## test passing the conf as a reference to new
my $conf = data_section( __PACKAGE__, 'new-arg.conf' );
$ghojo = Ghojo->new( {logging_conf => \$conf} );
ok(-e 't/new.log', 'logfile created');

## replace in previous conf string, write to file and
## test passing a filename to new
(my $file_conf = $conf) =~ s{t/new}{t/file};
spurt $file_conf, 't/log4perl.conf';
$ghojo = Ghojo->new( {logging_conf => 't/log4perl.conf'} );
ok(-e 't/file.log', 'logfile created');

## use a subclassed, redefined logging_conf()
$ghojo = Test::Ghojo::Log->new();
ok(-e 't/subclass.log', 'logfile created');

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
