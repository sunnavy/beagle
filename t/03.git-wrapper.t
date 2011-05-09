use Test::More;
use Beagle::Git::Wrapper;

my $git = Beagle::Git::Wrapper->new( root => 'fake' );

for my $sub (qw/root encoded_root has_changes_indexed has_changes_unindexed/) {
    can_ok( $git, $sub );
}

done_testing();
