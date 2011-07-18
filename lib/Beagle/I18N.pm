use strict;
use warnings;

package Beagle::I18N;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;
use Beagle::Util;

{
    my %import;
    my @po;
    check_po_root( catdir( share_root(), 'po' ), \%import );
    for my $plugin ( plugins() ) {
        catfile( share_root($plugin), 'po' );
    }

    Locale::Maketext::Lexicon->import( { _decode => 1, _auto => 1, %import } );
}

sub check_po_root {
    my $root   = shift;
    my $import = shift;
    return unless -e $root;

    opendir my $dh, $root or return;
    my @po;
    while ( my $file = readdir $dh ) {
        next unless $file =~ /(.+)\.po$/;
        my $lang = $1;
        push @{ $import->{$lang} }, Gettext => catfile( $root, $file );
    }
}

1;

