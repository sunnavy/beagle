package Beagle::Cmd::Command::names;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

has 'seprator' => (
    isa           => 'Str',
    is            => 'rw',
    traits        => ['Getopt'],
    documentation => 'seprator',
    default       => Beagle::Util::newline(),
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $all = roots();
    my $seprator = $self->seprator;
    $seprator =~ s{\\\\}{weird string which should never exist!!!}g;
    $seprator =~ s{\\r}{\r}g;
    $seprator =~ s{\\n}{\n}g;
    $seprator =~ s{\\t}{\t}g;
    $seprator =~ s{weird string which should never exist!!!}{\\}g;
    puts join $seprator, sort keys %$all;
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::names - show names

=head1 SYNOPSIS

    $ beagle names

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

