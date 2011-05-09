package Beagle::Cmd::Command::info;
use Encode;

use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'update' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'show',
    cmd_aliases   => "u",
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
    cmd_aliases   => "m",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $root = beagle_root('not die');

    if ( !$root ) {
        CORE::die "please specify beagle by --name or --root\n";
    }

    require Beagle::Handler;
    my $bh = Beagle::Handler->new( root => $root );
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

    if ( $self->update ) {
        my $updated = edit_text($template);

        if ( !$self->force && $template eq $updated ) {
            puts "aborted.";
            return;
        }

        my $updated_entry = $info->new_from_string( decode_utf8 $updated);
        if (
            $bh->update_info(
                $updated_entry, message => $self->message || "updated info"
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

sub usage_desc { "manage info" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::info - manage info


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

