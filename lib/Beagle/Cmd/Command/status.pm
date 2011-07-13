package Beagle::Cmd::Command::status;
use Encode;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "status for all the beagles",
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my @roots = beagle_root('not die');

    my $name_length;

    if ( $self->all || !@roots ) {
        my $all = beagle_roots;
        @roots = map { $all->{$_}{local} } keys %$all;
        $name_length = max_length( keys %$all ) + 1;
    }

    $name_length ||= length( root_name $roots[0] ) + 1;

    return unless @roots;

    require Beagle::Handle;

    require Text::Table;
    my $tb =
      Text::Table->new( 'name', 'type', 'size' );
    for my $root (@roots) {
        my $bh = Beagle::Handle->new( root => $root );
        my $type_info = entry_type_info();
        for my $attr ( sort map { $type_info->{$_}{plural} } %$type_info ) {
            $tb->add( $bh->name, $attr, size_info( $bh->$attr ) || 0 );
        }
        $tb->add( $bh->name, 'total size', format_bytes( $bh->total_size ) );
    }
    puts $tb;
}

sub size_info {
    my $entries = shift;
    return '' unless $entries;

    my $length = 0;
    for (@$entries) {
        my $len = length $_->body;
        $length += $len;
    }

    my $info = format_number( scalar @$entries );
    if (@$entries) {
        $info .= '(' . format_number($length) . ')';
    }
    return $info;
}

sub usage_desc { "show status" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::status - show status


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

