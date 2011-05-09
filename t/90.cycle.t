use Test::More;
use Beagle::Test;
eval { require Test::Memory::Cycle };
if ($@) {
    plan skip_all => 'no Test::Memory::Cycle';
    exit;
}

require Beagle::Handler;
my $root = create_tmp_beagle();
my $bh = Beagle::Handler->new( root => $root, type => 'fs' );
Test::Memory::Cycle::memory_cycle_ok($object);
done_testing();
