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

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "delete even it's ambiguous",
    cmd_aliases   => 'f',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/rm delete/ };

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle rm id [...]" unless @$args;

    my @deleted;
    my $entry_map;

    for my $i (@$args) {
        my @ret = resolve_entry( $i, handle => handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1 || $self->force;

        for my $ret (@ret) {
            my $id    = $ret->{id};
            my $bh    = $ret->{handle};
            my $entry = $ret->{entry};

            if ( $bh->delete_entry( $entry, commit => 0 ) ) {
                push @deleted, { handle => $bh, id => $entry->id };
            }
            else {
                die "failed to delete entry " . $entry->id;
            }
        }
    }

    if (@deleted) {
        my @handles = uniq map { $_->{handle} } @deleted;
        for my $bh (@handles) {
            my $msg = 'deleted '
              . join( ', ',
                map { $_->{id} }
                grep { $_->{handle}->root eq $bh->root } @deleted );
            $bh->backend->commit( message => $self->message || $msg );
        }

        my $msg = 'deleted ' . join( ', ', map { $_->{id} } @deleted );
        puts $msg . '.';
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::rm - delete entries

=head1 SYNOPSIS

    $ beagle rm id1 id2

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

