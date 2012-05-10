#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Lite::Model' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Lite::Model $DBIx::Lite::Model::VERSION, Perl $], $^X" );
