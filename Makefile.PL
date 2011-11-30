use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'shoppy',
    AUTHOR              => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM        => 'lib/shoppy.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3072,
        'Plack'      => 0.9974,
        'Template'   => 2.22,
        'Net::Twitter' => 3.18001,
        'Dancer::Plugin::Auth::Twitter' => 0.02,
        'LWP::Protocol::https' => 6.02,
        'Net::Amazon' => 0.61,
        'DBI'        => 1.616,
        'DBD::SQLite' => 1.33,
        'Dancer::Plugin::Database' => 1.50,
        'Net::Amazon' => 0.61,
        'WWW::Shorten::Bitly' => 1.17,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'shoppy-*' },
);
