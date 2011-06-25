package Beagle::Cmd::Command::mark;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has add => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'add marks',
    traits        => ['Getopt'],
);

has set => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set marks',
    traits        => ['Getopt'],
);

has delete => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'delete marks',
    traits        => ['Getopt'],
);

has unset => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'delete marks',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $updated;
    my $marks = entry_marks;

    for my $i (@$args) {

        my @ret = resolve_entry( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id = $ret[0]->{id};

        if ( $self->unset ) {
            if ( $marks->{$id} ) {
                delete $marks->{$id};
                $updated = 1 unless $updated;
            }
        }

        if ( $self->set ) {
            $marks->{$id} = {};
            for my $mark ( @{ $self->set } ) {
                $marks->{$id}{$mark} = 1;
                $updated = 1 unless $updated;
            }
        }

        if ( $self->add ) {
            for my $mark ( @{ $self->add } ) {
                if ( !$marks->{$id}{$mark} ) {
                    $marks->{$id}{$mark} = 1;
                    $updated = 1 unless $updated;
                }
            }
        }

        if ( $self->delete ) {
            for my $mark ( @{ $self->delete } ) {
                last unless $marks->{$id};
                if ( exists $marks->{$id}{$mark} ) {
                    delete $marks->{$id}{$mark};
                    $updated = 1 unless $updated;
                }
                delete $marks->{$id} unless %{ $marks->{$id} };
            }
        }
    }

    if ($updated) {
        set_entry_marks($marks);
        puts 'updated.';
    }
    else {
        puts 'no changes.';
    }
}

sub usage_desc { 'manage entry marks' }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::mark - manage entry marks

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

