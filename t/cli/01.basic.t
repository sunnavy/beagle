use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::Script::Run ':all';
my $beagle_cmd = Beagle::Test->beagle_command;

Beagle::Test->init_home;
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

done_testing();
