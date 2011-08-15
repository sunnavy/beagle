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
<command>

Available commands:

  commands: show beagle commands
      help: show beagle help

     alias: manage aliases
       att: manage attachments
     cache: manage cache
      cast: cast entries to another type
       cat: show entries
      cmds: show names of all the commands/aliases
   comment: create a comment
  comments: list comments
    config: configure beagle
    create: create an entry
    follow: follow beagles
      fsck: check integrity of kennel
       git: bridge to git
      info: manage info
      init: initialize a beagle
       log: show log
      look: open the beagle root directory with SHELL
        ls: list/search entries
      mark: manage entry marks
        mv: move entries to another beagle
      name: show name
   publish: generate static files
  relation: show beagle names of entries
    rename: rename a beagle
   rewrite: rewrite all the entries
        rm: delete entries
      root: show root
     shell: interactive shell
    spread: spread entries
    status: show status
     trust: trust beagles
  unfollow: unfollow beagles
   untrust: untrust beagles
    update: update entries
   version: show beagle version
       web: start web server

EOF

my $actual_help_output = last_script_stdout;

if ( is_windows() ) {
    is( $actual_help_output, 'beagle.BAT ' . $help_output, 'help output' );
}
else {
    is( $actual_help_output, 'beagle ' . $help_output, 'help output' );
}

run_ok( $beagle_cmd, ['commands'], 'commands' );
is( last_script_stdout(), $actual_help_output, 'commands output' );

run_ok( $beagle_cmd, ['cmds'], 'cmds' );
$expect = join newline(), qw/
  alias att cache cast cat cmds commands comment comments config create
  follow fsck git help info init log look ls mark mv name publish relation rename 
  rewrite rm root shell spread status trust unfollow untrust update version web/;
is( last_script_stdout(), $expect . newline(), 'cmds output' );

run_ok( $beagle_cmd, ['root'], 'root' );
is( last_script_stdout(), $root . newline(), 'root output' );
run_ok( $beagle_cmd, ['roots', '-v'], 'roots' );
is( last_script_stdout(), join( ' ', '@', 'external', 'fs', $root ) . newline(),
    'roots output' );


run_ok( $beagle_cmd, ['status'], 'status' );
my $name = $root;
if ( is_windows ) {
    $name =~ s!:!_!g;
}

$expect = <<"EOF";
name    type       size
$name articles   0   
$name tasks      0   
$name barks      0   
$name reviews    0   
$name comments   0   
$name total size
EOF

$out = last_script_stdout();
like( $out, qr/^name\s+type\s+size\s*trust\s*$/m, 'status output' );
like( $out, qr/\Q$name\E\s+articles\s+0\s*-\s*$/m, 'status output articles part' );
like( $out, qr/\Q$name\E\s+barks\s+0\s*-\s*$/m, 'status output barks part' );
like( $out, qr/\Q$name\E\s+reviews\s+0\s*-\s*$/m, 'status output reviews part' );
like( $out, qr/\Q$name\E\s+tasks\s+0\s*-\s*$/m, 'status output tasks part' );
like( $out, qr/\Q$name\E\s+comments\s+0\s*-\s*$/m, 'status output comments part' );
like(
    $out,
    qr/\Q$name\E\s+total size\s+[\d.]+K\s*0\s*\Z/m,
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

