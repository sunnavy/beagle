package Beagle::Cmd::Command::configs;
use Beagle::Util;
use Any::Moose;
use Encode;
extends qw/Beagle::Cmd::GlobalCommand/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $core = core_config();

    if (@$args) {
        for my $name (@$args) {
            puts join ': ', $name, defined $core->{$name} ? $core->{$name} : '';
        }
    }
    else {
        for my $name ( sort keys %$core ) {
            puts join ': ', $name, defined $core->{$name} ? $core->{$name} : '';
        }
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::configs - show beagle configurations

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

