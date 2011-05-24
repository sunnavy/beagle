package Beagle::Model::Comment;
use Any::Moose;
use Beagle::Util;
extends 'Beagle::Model::Entry';

has 'parent_id' => (
    isa => 'Str',
    is  => 'rw',
);

override 'serialize_meta' => sub {
    my $self = shift;
    my %opt  = @_;
    my $str  = '';
    $str .= 'parent_id: ' . $self->parent_id . "\n";
    $str .= super;
    return $str;
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

