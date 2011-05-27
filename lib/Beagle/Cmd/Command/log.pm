package Beagle::Cmd::Command::log;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has 'id' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'entry id',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my ( $id, $entry, $bh );
    if ( $self->id ) {
        my $i = $self->id;
        my @ret = resolve_entry( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        $id    = $ret[0]->{id};
        $bh    = $ret[0]->{handler};
        $entry = $ret[0]->{entry};
    }
    require Beagle::Handler;
    $bh ||= Beagle::Handler->new( root => beagle_root() );

    my ( $ret, $out ) =
      $bh->backend->log( @$args, $entry ? ( '--follow', $entry->path ) : () );

    # git output is encoded already
    print $out if $ret;
}

sub usage_desc { "show log" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::log - show log


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

