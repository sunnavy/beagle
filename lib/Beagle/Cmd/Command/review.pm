package Beagle::Cmd::Command::review;
use Any::Moose;
extends qw/Beagle::Cmd::Command::article/;

has 'type' => (
    isa     => 'Str',
    is      => 'ro',
    default => 'review',
);

has isbn => (
    isa           => "Str",
    is            => "rw",
    documentation => "isbn",
    traits        => ['Getopt'],
);

has 'location' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "location",
    traits        => ['Getopt'],
);

has 'published' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "published date",
    traits        => ['Getopt'],
);

has 'link' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "remote url for the work being reviewed",
    traits        => ['Getopt'],
);

has 'price' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "price",
    traits        => ['Getopt'],
);

has 'publisher' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "publisher",
    traits        => ['Getopt'],
);

has 'author' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "author",
    traits        => ['Getopt'],
);

has 'translator' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => "translator",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;


1;

__END__

=head1 NAME

Beagle::Cmd::Command::review - create a review

=head1 SYNOPSIS

    $ beagle review --isbn 9787020071609 --location hangzhou --writer \
        'Mark Twain' --published 1989-09-01  ...

checkout C<article> and C<entry> commands to find more examples.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

