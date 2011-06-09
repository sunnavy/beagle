use strict;
use warnings;

package Beagle::I18N;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;
use Beagle::Util;
{
    my %import;
    my @po;
    opendir my $dh, catdir( beagle_share_root(), 'po' );
    while ( my $file = readdir $dh ) {
        push @po, $1 if $file =~ /(.+)\.po$/;
    }

    for my $lang (@po) {
        $import{$lang} =
          [ Gettext => catfile( beagle_share_root(), 'po', "$lang.po" ) ];
    }

    Locale::Maketext::Lexicon->import( { _decode => 1, _auto => 1, %import } );
}

1;

