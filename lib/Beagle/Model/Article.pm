package Beagle::Model::Article;
use Any::Moose;
use Beagle::Util;
extends 'Beagle::Model::Entry';

has 'title' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'update' => (
    isa => 'Str',
    is  => 'rw',
);

override 'serialize_meta' => sub {
    my $self = shift;
    my $str  = '';
    $str .= $self->_serialize_meta( $_ ) for qw/title/;
    $str .= super;

    if ( $self->update ) {
        $str .= 'update: ' . $self->update . "\n";
    }

    return $str;
};

sub summary {
    my $self = shift;

    my $value = $self->title || $self->body;
    $self->_summary( $value, @_ );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

