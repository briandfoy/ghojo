requires 'Carp';
requires 'Mojolicious';
requires 'Mojo::URL';
requires 'Mojo::UserAgent';
requires 'Log::Log4perl';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
    requires 'File::Spec::Functions';
};

on test => sub {
    requires 'Test::More',            '0.95';
    requires 'Test::Builder::Tester', '1.04';
    requires 'Test::Builder',         '1.001006';
    requires 'Test::utf8';
};

