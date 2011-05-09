package Beagle::Model::Attachment;
use Any::Moose;
use Beagle::Util;

has 'root' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { beagle_root() },
);

has 'path' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @ids  = split_id( $self->parent_id );
        return catdir( 'attachments', @ids, $self->name );
    },
);

with 'Beagle::Role::File';

has 'is_raw' => (
    isa     => 'Bool',
    is      => 'ro',
    default => 1,
    lazy    => 1,
);

has 'parent_id' => (
    isa => 'Str',
    is  => 'rw',
);

has 'name' => (
    isa => 'Str',
    is  => 'ro',
);

has 'content_file' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'mime_type' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    builder => '_set_mime_type',
);

use MIME::Types;
my $mime_types = MIME::Types->new;

sub _set_mime_type {
    my $self = shift;
    my $name = $self->name;
    my $type;
    if ( $name && $name =~ /.*\.(\S+)\s*$/i ) {
        $type = $mime_types->mimeTypeOf($1);
    }
    return "$type" || 'application/octet-stream';
}

sub serialize {
    my $self = shift;
    return $self->content;
}

sub type { 'attachment' }

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

