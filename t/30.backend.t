use Test::More;
use Beagle::Backend;

my $backend = Beagle::Backend->new( root => 'fake' );

for my $sub (qw/type root encoded_root create read update delete/) {
    can_ok( $backend, $sub );
}

isa_ok( $backend, 'Beagle::Backend::git', 'default backend is git' );
is( $backend->type, 'git',  'default type is git' );
is( $backend->root, 'fake', 'root is set' );

$backend = Beagle::Backend->new( type => 'fs', root => 'fake' );
isa_ok( $backend, 'Beagle::Backend::fs', 'backend is set to fs' );
is( $backend->type, 'fs', 'type is set to git' );

done_testing();
