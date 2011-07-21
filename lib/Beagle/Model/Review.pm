package Beagle::Model::Review;
use Any::Moose;
use Beagle::Util;
extends 'Beagle::Model::Article';

has 'isbn' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'published' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'link' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'price' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'publisher' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'writer' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'translator' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'location' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);


override 'serialize_meta' => sub {
    my $self = shift;
    my $str  = super;
    for (
        qw/isbn writer translator publisher published price link location/ )
    {
        $str .= $self->_serialize_meta( $_ );
    }
    return $str;
};

sub cover {
    my $self     = shift;
    my @exts = qw/jpg png gif/;
    my @names = ( 'cover', $self->isbn );
    my @ids = split_id( $self->id );
    for my $name (@names) {
        next unless $name;
        for my $ext (@exts) {
            my $file =
              catfile( $self->root, 'attachments', @ids, "$name.$ext" );
            return "$name.$ext" if -e $file;
        }
    }
    return;
}

sub extra_meta_fields_in_web_view {
    [
        qw/writer translator publisher published isbn/
    ];
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

