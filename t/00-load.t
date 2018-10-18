#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SPLAT' ) || print "Bail out!\n";
}

diag( "Testing SPLAT $SPLAT::VERSION, Perl $], $^X" );
