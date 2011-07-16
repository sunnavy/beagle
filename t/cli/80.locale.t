use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';

use Beagle::Util;
use Encode;

$ENV{BEAGLE_CACHE} = 1;
my $beagle_cmd = Beagle::Test->beagle_command;

Beagle::Test->init_kennel;

run_ok( $beagle_cmd, [qw/init --name 甲乙/], 'init 甲乙' );
is( last_script_stdout(), 'initialized.' . newline(), 'init output' );

run_ok( $beagle_cmd, [qw/rename 甲乙 丙丁/], 'rename foo to 丙丁' );
is(
    last_script_stdout(),
    'renamed 甲乙 to 丙丁.' . newline(),
    'rename output'
);

run_ok( $beagle_cmd, [qw/root/], 'root cmd' );
like( last_script_stdout(), qr/丙丁/, 'current root' );

run_ok( $beagle_cmd, [qw/bark test -n 丙丁/], 'create bark' );
ok( last_script_stdout() =~ /^created (\w{32}).\s+$/, 'create bark output' );

opendir my $dh, catdir( $ENV{BEAGLE_KENNEL}, 'cache' );
my ($file) =
  map { decode( locale_fs => $_ ) }
  grep { $_ ne '.' && $_ ne '..' } readdir $dh;
is( $file, decode( 'utf8', '丙丁.drafts' ), 'cache is enabled' );

run_ok( $beagle_cmd, [qw/unfollow 丙丁/], 'create bark' );
is(
    last_script_stdout(),
    'unfollowed 丙丁.' . newline(),
    'unfollow 丙丁 output'
);

opendir $dh, catdir( $ENV{BEAGLE_KENNEL}, 'cache' );
ok( !( grep { $_ ne '.' && $_ ne '..' } readdir $dh ), 'cache is deleted' );

done_testing();

