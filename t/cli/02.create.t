use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
use Beagle::Util;
use File::Temp 'tempdir';
my $beagle_cmd = Beagle::Test->beagle_command;

Beagle::Test->init_home;

{
    run_ok( $beagle_cmd, [qw/create --name foo/], 'create foo' );
    is( last_script_stdout(), 'created.' . newline(), 'create output' );

    run_ok( $beagle_cmd, [qw/rename foo bar/], 'rename foo to bar' );
    is( last_script_stdout(), 'renamed foo to bar.' . newline(), 'create output' );
}

{
    my $dir = catdir( tempdir( CLEANUP => 1 ), 'foo' );
    run_ok( $beagle_cmd, [ qw/create/, $dir ], 'create foo' );
    my $expect =
      "created, please run `beagle follow $dir --type git` to continue.";
    is( last_script_stdout(), $expect . newline(), 'create output' );
}

done_testing();

