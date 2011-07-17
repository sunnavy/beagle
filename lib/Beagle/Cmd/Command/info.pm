package Beagle::Cmd::Command::info;
use Encode;

use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'set' => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set',
    traits        => ['Getopt'],
);

has 'unset' => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'unset',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use editor',
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'force',
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => 'm',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $root = current_root('not die');

    if ( !$root ) {
        die "please specify beagle by --name or --root";
    }

    require Beagle::Handle;
    my $bh = Beagle::Handle->new( root => $root );
    my $info = $bh->info;

    my $template = encode_utf8 $info->serialize(
        $self->verbose
        ? (
            created => 1,
            updated => 1,
            id      => 1,
          )
        : (
            created => undef,
            updated => undef,
            id      => undef,
        )
    );

    if ( $self->edit || $self->set || $self->unset ) {

        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $key, $value ) = split /=/, $item, 2;
                if ( $info->can($key) ) {
                    $info->$key($value);
                }
                else {
                    warn "unknown key: $key";
                }
            }
        }

        if ( $self->unset ) {

            for my $key ( @{ $self->unset } ) {
                if ( $info->can($key) ) {
                    $info->$key('');
                }
                else {
                    warn "unknown key: $key";
                }
            }
        }

        $template = encode_utf8 $info->serialize(
            $self->verbose
            ? (
                created => 1,
                updated => 1,
                id      => 1,
              )
            : (
                created => undef,
                updated => undef,
                id      => undef,
            )
        );

        if ( $self->edit ) {

            my $updated = edit_text($template);

            if ( !$self->force && $template eq $updated ) {
                puts "aborted.";
                return;
            }

            $info = $info->new_from_string( decode_utf8 $updated);
        }

        if (
            $bh->update_info(
                $info, message => $self->message || "updated info"
            )
          )
        {
            puts "updated info.";
        }
        else {
            die "failed to update info.";
        }
    }
    else {
        puts decode_utf8 $template;
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::info - manage info

=head1 SYNOPSIS

    $ beagle info
    $ beagle info --edit
    $ beagle info --set url=http://sunnavy.net
    $ beagle info --unset url

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

