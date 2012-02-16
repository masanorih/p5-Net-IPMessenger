#!perl -T

use Test::More;

if ( $ENV{TEST_POD} || $ENV{TEST_ALL} ) {
    eval "use Test::Pod 1.14";
    plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
}
else {
    plan skip_all => 'set TEST_POD or TEST_ALL for testing POD';
}

all_pod_files_ok();
