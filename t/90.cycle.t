use Test::More;
use Beagle::Test;
eval { require Test::Memory::Cycle };
if ($@) {
    plan skip_all => 'no Test::Memory::Cycle';
    exit;
}

use Beagle::Handler;
Beagle::Test->init;
my $bh = Beagle::Handler->new();
Test::Memory::Cycle::memory_cycle_ok($object, 'no memory cycle');
done_testing();
