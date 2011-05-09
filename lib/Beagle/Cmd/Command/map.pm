package Beagle::Cmd::Command::map;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has 'update' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'show',
    cmd_aliases   => "u",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    if ( $self->update ) {
        my $roots = beagle_roots();
        require Beagle::Handler;
        my $map = {};

        for my $name ( keys %$roots ) {
            my $bh = Beagle::Handler->new( root => $roots->{$name}{local} );
            for my $entry ( @{ $bh->comments }, @{ $bh->entries } ) {
                $map->{ $entry->id } = $name;
            }
        }

        set_entry_map($map);
        puts "updated map.";
    }
    else {
        my $map = entry_map;
        my @ids;

        if (@$args) {
            for my $id (@$args) {
                push @ids, grep { /^$id/ } keys %$map;
            }
        }
        else {
            @ids = keys %$map;
        }

        return unless @ids;

        my $name_length = max_length( map { $map->{$_} } @ids ) + 1;
        $name_length = 5 if $name_length < 5;

        require Text::Table;
        my $tb = Text::Table->new();
        $tb->load( map { [ $_, $map->{$_} ] } @ids );
        puts $tb;
    }
}

sub usage_desc { "manage entry map" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::map - manage entry map

=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

