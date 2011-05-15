use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Beagle::Util;
use Test::Script::Run ':all';
my $beagle_cmd = Beagle::Test->beagle_command;

my $root = Beagle::Test->init( name => 'foo', email => 'foobar@baz.com' );
my ( $out, $expect );

run_ok( $beagle_cmd, ['version'], 'version' );
$out = last_script_stdout();
require Beagle;
is( $out, 'beagle version ' . $Beagle::VERSION . newline(), 'version output' );

run_ok( $beagle_cmd, ['help'], 'help' );

my $help_output = <<EOF;
Available commands:

  commands: list the application's commands
      help: display a command's help screen

     alias: show command alias(es)
   article: create a new article
       att: manage attachments
     cache: cache
      cmds: show names of all the commands/aliases
   comment: create a new comment
  comments: list comments
    config: config beagle
    create: create a new beagle
     entry: create a new entry
    follow: follow a beagle
      fsck: check integrity of beagles
       git: bridge to git
      info: manage info
       log: show log
        ls: list/search entries
       map: manage entry map
        mv: move entries to another beagle
    rename: rename a beagle
    review: create a review
   rewrite: rewrite all entries
        rm: delete entries
      root: show root
     shell: interactive shell
      show: show entries
    spread: spread an entry
    status: show status
  unfollow: unfollow beagle(s)
    update: update an entry
   version: show beagle version
       web: start web server

EOF

is( last_script_stdout(), $help_output, 'help output' );
run_ok( $beagle_cmd, ['commands'], 'commands' );
is(
    last_script_stdout(),
    "beagle <command>\n\n$help_output",
    'commands output'
);

run_ok( $beagle_cmd, ['cmds'], 'cmds' );
$expect =
'alias article att cache cmds commands comment comments config create entry follow fsck git help info log ls map mv rename review rewrite rm root shell show spread status unfollow update version web';
is( last_script_stdout(), $expect . newline(), 'cmds output' );

run_ok( $beagle_cmd, ['root'], 'root' );
is( last_script_stdout(), $root . newline(), 'root output' );

run_ok( $beagle_cmd, ['roots'], 'roots' );
is( last_script_stdout(), join( ' ', '@', 'external', 'fs', $root ) . newline(),
    'roots output' );

run_ok( $beagle_cmd, ['status'], 'status' );
$expect = <<"EOF";
name    type       size
$root articles   0   
$root tasks      0   
$root barks      0   
$root reviews    0   
$root comments   0   
$root total size
EOF

$out = last_script_stdout();
like( $out, qr/^name\s+type\s+size\s*$/m, 'status output' );
like( $out, qr/\Q$root\E\s+articles\s+0\s*$/m, 'status output articles part' );
like( $out, qr/\Q$root\E\s+barks\s+0\s*$/m, 'status output barks part' );
like( $out, qr/\Q$root\E\s+reviews\s+0\s*$/m, 'status output reviews part' );
like( $out, qr/\Q$root\E\s+tasks\s+0\s*$/m, 'status output tasks part' );
like( $out, qr/\Q$root\E\s+comments\s+0\s*$/m, 'status output comments part' );
like(
    $out,
    qr/\Q$root\E\s+total size\s+[\d.]+K\s*\Z/m,
    'status output total size part'
);

run_ok( $beagle_cmd, ['fsck'], 'fsck' );
is( last_script_stdout(), '', 'fsck output: we are fine initially' );

run_ok( $beagle_cmd, ['info'], 'info' );
$out = last_script_stdout();
like( $out, qr/name: foo$/m, 'get name' );
like( $out, qr/email: foobar\@baz\.com$/m, 'get email' );

run_ok(
    $beagle_cmd,
    [ 'info', '--set', 'name=foobar' ],
    'update name'
);
is( last_script_stdout(), 'updated info.' . newline(), 'update output' );

run_ok( $beagle_cmd, ['info'], 'info' );
like( last_script_stdout(),
    qr/name: foobar$/m,
    'name in indeed updated'
);

done_testing();

