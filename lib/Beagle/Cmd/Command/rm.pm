package Beagle::Cmd::Command::rm;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => "m",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle rm id [...]" unless @$args;

    my @deleted;
    my $entry_map;

    for my $i (@$args) {
        my @ret = resolve_id( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_id($i) or die_id_invalid($i);
        }
        die_id_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handler};
        my $entry = $ret[0]->{entry};

        if ( $bh->delete_entry( $entry, commit => 0 ) ) {
            push @deleted, { handler => $bh, id => $entry->id };
        }
        else {
            die "failed to delete entry " . $entry->id;
        }
    }

    if (@deleted) {
        my $msg = 'deleted ' . join( ', ', map { $_->{id} } @deleted );
        my @handlers = uniq map { $_->{handler} } @deleted;
        for my $bh (@handlers) {
            $bh->backend->commit( message => $self->message || $msg );
        }
        puts $msg . '.';
    }
}

sub usage_desc { "delete entries" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::rm - delete entries


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

