use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Test::WWW::Mechanize;
use Beagle::Handler;

my ( $url, $root ) = start_server( '--admin' );

my $bh = Beagle::Handler->new( root => $root );

my $article = Beagle::Model::Article->new(
    title => 'title foo',
    body  => 'body foo',
);
ok( $bh->create_entry( $article ), 'created article' );

my $m = Test::WWW::Mechanize->new;

my %walked = ( $url => 1 );
test_page($url);

sub test_page {
    my $url = shift;
    $m->get_ok( $url );

    for my $link ( $m->find_all_links() ) {
        my $uri = URI->new( $link->url_abs );
        next unless $uri->scheme eq 'http' && $link->base() eq $url;
        next if $walked{$uri->as_string}++;
        test_page( $uri->as_string );
    }
}

done_testing();

