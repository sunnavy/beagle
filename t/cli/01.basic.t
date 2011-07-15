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
beagle <command>

Available commands:

  commands: show beagle commands
      help: show beagle help

     alias: manage aliases
   article: create an article
       att: manage attachments
     cache: manage cache
      cast: cast entries to another type
       cat: show entries
      cmds: show names of all the commands/aliases
   comment: create a comment
  comments: list comments
    config: configure beagle
    create: create a beagle
     entry: create an entry
    follow: follow beagles
      fsck: check integrity of kennel
       git: bridge to git
      info: manage info
       log: show log
      look: open the beagle root directory with SHELL
        ls: list/search entries
       map: manage entry map
      mark: manage entry marks
        mv: move entries to another beagle
    rename: rename a beagle
    review: create a review
        rm: delete entries
      root: show root
     shell: interactive shell
    spread: spread entries
    status: show status
  unfollow: unfollow beagles
    update: update entries
   version: show beagle version
       web: start web server

EOF

is( last_script_stdout(), $help_output, 'help output' );
run_ok( $beagle_cmd, ['commands'], 'commands' );
is(
    last_script_stdout(),
    $help_output,
    'commands output'
);

run_ok( $beagle_cmd, ['cmds'], 'cmds' );
$expect = join newline(), qw/
  alias article att cache cast cat cmds commands comment comments config create
  entry follow fsck git help info log look ls map mark mv rename review
  rm root shell spread status unfollow update version web/;
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

