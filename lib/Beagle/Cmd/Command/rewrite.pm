package Beagle::Cmd::Command::rewrite;
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

    my @bh;
    local $ENV{BEAGLE_CACHE};    # no cache

    my $root = current_root('not die');
    require Beagle::Handle;
    if ($root) {
        push @bh, Beagle::Handle->new( root => $root );
    }
    else {
        my $all = roots();
        push @bh,
          map { Beagle::Handle->new( root => $all->{$_}{local} ) } keys %$all;
    }

    require Email::Address;
    for my $bh (@bh) {
        my $default_address =
          Email::Address->new( $bh->info->name, $bh->info->email )->format;
        for my $id ( keys %{ $bh->map } ) {
            my $entry = $bh->map->{$id};

            $entry->author($default_address) unless $entry->author;
            $bh->update_entry( $entry, commit => 0 )
              or die "failed to update entry " . $entry->id;
        }
        $bh->backend->commit( message => $self->message
              || 'rewrote the whole beagle' );
    }
    puts "rewrote.";
}

sub usage_desc { "rewrite all entries" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::rewrite - rewrite all entries


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

