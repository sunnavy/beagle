use Test::More;
use Beagle::Handler;
use Beagle::Test;

my $root = create_tmp_beagle();
my $bh = Beagle::Handler->new( root => $root, type => 'fs' );
is( $bh->root, $root, 'root' );
is( $bh->name, $root, 'name' );
is( $bh->type, 'fs',  'type' );
isa_ok( $bh->backend, 'Beagle::Backend::fs' );

for $method (
    qw/cache info comments map comments_map entries
    attachments_map updated sites list articles barks reviews tasks
    entry_info
    /
  )
{
    can_ok( $bh, $method );
}

done_testing();
