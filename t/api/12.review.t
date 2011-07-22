use Test::More;
use Beagle::Model::Review;

my $review = Beagle::Model::Review->new();

isa_ok( $review, 'Beagle::Model::Review' );
isa_ok( $review, 'Beagle::Model::Entry' );

for my $attr (qw/isbn published publisher writer translator link price location/) {
    can_ok( $review, $attr );
}

for my $method (qw/cover/) {
    can_ok( $review, $method );
}

done_testing();
