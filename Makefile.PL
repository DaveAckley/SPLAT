use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install 'install_share';

install_share 'lib/ulam';
install_share 'demos';

WriteMakefile(
    NAME             => 'App::Splattr',
    AUTHOR           => q{Dave Ackley <ackley@ackleyshack.com>},
    VERSION_FROM     => 'lib/SPLAT.pm',
    ABSTRACT_FROM    => 'lib/SPLAT.pm',
    LICENSE          => 'gpl_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
	'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
	'File::ShareDir'    => 0,
    },
    INSTALLDIRS => 'vendor',
    EXE_FILES => [('splattr')],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SPLAT-*' },
);

package MY;
use File::ShareDir::Install qw( postamble );
