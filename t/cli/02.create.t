use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
use File::Temp 'tempdir', 'tempfile';
my $beagle_cmd = Beagle::Test->beagle_command;

Beagle::Test->init_home;

{
    run_ok( $beagle_cmd, [qw/create --name foo/], 'created foo' );
    my $out = 'created.';
    is( last_script_stdout(), $out . newline(), 'create output' );
}

{
    my $dir = catdir( tempdir( CLEANUP => 1 ), 'foo' );
    run_ok( $beagle_cmd, [ qw/create/, $dir ], 'created foo' );
    my $out = "created, please run `beagle follow $dir --type git` to continue.";
    is( last_script_stdout(), $out . newline(), 'create output' );
}

done_testing();

