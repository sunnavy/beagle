package Beagle::Cmd::Command::marks;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has set => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'set marks',
    traits        => ['Getopt'],
    default       => sub { [] },
);

has unset => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    documentation => 'unset marks',
    traits        => ['Getopt'],
    default       => sub { [] },
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $updated;
    my $marks = entry_marks;

    my @ids;
    for my $i (@$args) {
        my @ret = resolve_entry( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id = $ret[0]->{id};
        push @ids, $id;
    }

    @ids = keys %$marks;

    if (@ids) {
        require Text::Table;
        my $tb = Text::Table->new();
        $tb->load( map { [ $_, join ', ', sort keys %{ $marks->{$_} } ] 
                } grep { %{$marks->{$_}} } @ids );
        puts $tb;
    }
}

sub usage_desc { 'show entry marks' }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::marks - show entry marks

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

