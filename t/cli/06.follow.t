use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Beagle::Util;
use Test::Script::Run ':all';
my $type = Beagle::Test::which('git') ? 'git' : 'fs';

my $beagle_cmd = Beagle::Test->beagle_command;

use File::Temp 'tempdir';
my $kennel = Beagle::Test->init_kennel;

my $tmpdir = tempdir( CLEANUP => 1 );
for my $name (qw/foo bar/) {
    my $root = catdir( $tmpdir, $name );
    run_ok( $beagle_cmd, [ 'init', $root ], "init $root" );
    my $expect =
      "initialized, please run `beagle follow $root --type $type` to continue.";
    is( last_script_stdout(), $expect . newline(), "init $root output" );
}

my $foo = catdir( $tmpdir, 'foo' );
run_ok( $beagle_cmd, [ 'follow', $foo, qw/--name baz/ ], "follow $foo as baz" );
is( last_script_stdout(), "followed $foo." . newline(), "follow $foo output" );

my $bar = catdir( $tmpdir, 'bar' );
run_ok( $beagle_cmd, [ 'follow', $bar ], "follow $bar" );
is( last_script_stdout(), "followed $bar." . newline(), "follow $bar output" );

run_ok( $beagle_cmd, ['roots'], "roots" );
like(
    last_script_stdout(),
    qr/^\s+baz\s+$type\s+\Q$foo\E\s*$/m,
    "$foo is indeed followed"
);
like(
    last_script_stdout(),
    qr/^\s+bar\s+$type\s+\Q$bar\E\s*$/m,
    "$bar is indeed followed"
);

local $ENV{BEAGLE_NAME} = 'baz';
run_ok( $beagle_cmd, ['roots'], "roots" );
like(
    last_script_stdout(),
    qr/^\@\s+baz\s+$type\s+\Q$foo\E\s*$/m,
    "$foo is current beagle"
);
like(
    last_script_stdout(),
    qr/^\s+bar\s+$type\s+\Q$bar\E\s*$/m,
    "$bar is not current"
);

run_ok( $beagle_cmd, ['root'], 'root' );
is( last_script_stdout(), catdir( $kennel, 'roots', 'baz' ) . newline(),
    'root output' );

run_ok( $beagle_cmd, [ 'unfollow', 'bar' ], 'unfollow bar' );
is( last_script_stdout(), 'unfollowed bar.' . newline(),
    'unfollow bar output' );
run_ok( $beagle_cmd, [ 'unfollow', 'baz' ], 'unfollow baz' );
is( last_script_stdout(), 'unfollowed baz.' . newline(),
    'unfollow baz output' );

run_ok( $beagle_cmd, ['roots'], "roots" );
is( last_script_stdout(), '', 'empty roots' );

done_testing();

