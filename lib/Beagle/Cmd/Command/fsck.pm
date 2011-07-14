package Beagle::Cmd::Command::fsck;
use Beagle::Util;
use File::Copy 'move';
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has rescue => (
    isa           => "Bool",
    is            => "rw",
    documentation => "rescue",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $all = backend_roots();
    for my $name ( keys %$all ) {
        my $local = $all->{$name}{local};
        next if -d $local;
        puts "$name is missing";
        if ( $self->rescue ) {
            puts "rescuing $name";
            system( qw/beagle follow/, $all->{$name}{remote}, '--name', $name )
              && die "failed to follow $all->{$name}{remote}: $?";
        }
    }
}

sub usage_desc { "check integrity of beagles" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::fsck - check integrity of beagles

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

