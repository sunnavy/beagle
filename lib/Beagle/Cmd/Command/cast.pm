package Beagle::Cmd::Command::cast;
use Any::Moose;
use Beagle::Util;
use Encode;
extends qw/Beagle::Cmd::Command/;

has 'type' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'cast type',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle cast --type new_type id1 id2 [...]"
      unless @$args && $self->type;

    my $type      = ucfirst lc $self->type;
    my $new_class = 'Beagle::Model::' . $type;
    for my $i (@$args) {
        my @ret = resolve_entry( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handler};
        my $entry = $ret[0]->{entry};

        my $new_object = $new_class->new(%$entry);
        if (
            $bh->create_entry(
                $new_object, message => "cast $id to type $type"
            )
          )
        {
            $bh->delete_entry($entry);
        }
    }
    puts 'casted.';
}

sub usage_desc { "cast entres to another type" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::cast - cast entries to another type


=head1 AUTHOR

    sunnavy  <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

