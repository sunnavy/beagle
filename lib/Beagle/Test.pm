package Beagle::Test;
use strict;
use warnings;
use base 'Exporter';
use Beagle::Util;
use File::Temp 'tempdir';
use Test::More;
our @EXPORT = qw/create_tmp_beagle/;

sub create_tmp_beagle {
    my $root = tempdir( CLEANUP => 1 );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( create_beagle( type => 'fs', root => $root, @_ ), "created beagle $root" );
    return $root;
}

1;
__END__


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

