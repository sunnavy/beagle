package Beagle::Cmd::Command::update;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'force',
    traits        => ['Getopt'],
);

has 'set' => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => "Bool",
    is            => "rw",
    documentation => "edit with editor?",
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => "m",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/update edit/ };

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle update id [...]" unless @$args;

    for my $i (@$args) {
        my @ret = resolve_entry( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handler};
        my $entry = $ret[0]->{entry};

        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $key, $value ) = split /=/, $item, 2;
                if ( $entry->can($key) ) {
                    $entry->$key($value);
                }
                else {
                    warn "unknown key: $key\n";
                }
            }
        }

        if ( $self->edit || !$self->set ) {
            my $template = encode_utf8 $entry->serialize(
                $self->verbose
                ? (
                    path      => 1,
                    created   => 1,
                    updated   => 1,
                    id        => 1,
                    parent_id => 1,
                  )
                : (
                    path      => undef,
                    created   => undef,
                    updated   => undef,
                    id        => undef,
                    parent_id => undef,
                )
            );

            my $updated = edit_text($template);

            if ( !$self->force && $template eq $updated ) {
                puts "aborted.";
                return;
            }
            my $updated_entry =
              $entry->new_from_string( decode_utf8($updated),
                $self->verbose ? () : ( id => $entry->id ) );
            $updated_entry->original_path( $entry->original_path );

            unless ( $self->verbose ) {
                if ( $entry->can('parent_id') ) {
                    $updated_entry->parent_id( $entry->parent_id );
                }

                $updated_entry->created( $entry->created );
                $updated_entry->updated(time);
            }

            $updated_entry->timezone( $bh->info->timezone )
              if $bh->info->timezone;
            $entry = $updated_entry;
        }

        if (
            $bh->update_entry(
                $entry, message => $self->message || "updated $id"
            )
          )
        {
            puts 'updated ', $entry->id, ".";
        }
        else {
            die "failed to update " . $entry->id . '.';
        }
    }
}

sub usage_desc { "update an entry" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::update - update an entry


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

