package Beagle::Cmd::Command::create;
use Encode;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;
use Any::Moose 'Util::TypeConstraints', => [ 'enum' ];

has draft => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'is draft',
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'force to create even no changes in editor',
    traits        => ['Getopt'],
);

enum 'BeagleEntryType'   => entry_types();

has 'type' => (
    isa           => 'BeagleEntryType',
    is            => 'rw',
    cmd_aliases   => 't',
    documentation => 'type',
    traits        => ['Getopt'],
);

has author => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'author',
    traits        => ['Getopt'],
);

has tags => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'tags',
    traits        => ['Getopt'],
);

has body => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'body',
    traits        => ['Getopt'],
);

has 'body-file' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'body_file',
    documentation => 'body file path',
    traits        => ['Getopt'],
);

has 'body-file-encoding' => (
    isa           => 'Str',
    is            => 'rw',
    accessor      => 'body_file_encoding',
    documentation => 'body file encoding',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'use editor',
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => 'm',
    traits        => ['Getopt'],
);

has attachments => (
    isa           => 'ArrayRef[Str]',
    is            => 'rw',
    cmd_aliases   => 'a',
    documentation => 'attachments',
    traits        => ['Getopt'],
);

has format => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'format',
    traits        => ['Getopt'],
);

sub class {
    my $self = shift;
    die 'no type specified' unless $self->type;
    return entry_type_info->{ lc $self->type }{class};
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $bh = handle() or die "please specify beagle by --name or --root";

    $opt->{tags} = to_array( delete $opt->{tags} );

    if ( $self->body_file && !defined $opt->{body} ) {
        $opt->{body} = decode(
            $self->body_file_encoding || 'utf8',
            read_file( $self->body_file )
        ) or die $!;
    }
    $opt->{body} = join ' ', @$args if @$args && !defined $opt->{body};

    my $entry;
    if ( defined $opt->{body} && !$self->edit ) {
        $entry = $self->class->new(
            map { $_ => $opt->{$_} }
            grep { defined $opt->{$_} } keys %$opt
        );
    }
    else {
        my $temp = $self->class->new(
            map { $_ => $opt->{$_} }
            grep { defined $opt->{$_} } keys %$opt
        );
        $temp->timezone( $bh->info->timezone ) if $bh->info->timezone;
        $temp->author( $self->author
              || Email::Address->new( $bh->info->name, $bh->info->email )->format );

        my $template = $temp->serialize(
            $self->verbose
            ? (
                path    => 1,
                created => 1,
                updated => 1,
                id      => 1,
              )
            : (
                path    => 0,
                created => 0,
                updated => 0,
                id      => 0,
            )
        );
        my $updated = edit_text($template);

        if ( !$self->force && $template eq $updated ) {
            puts "aborted.";
            return;
        }

        $entry = $self->class->new_from_string( decode_utf8 $updated );
    }

    $entry->timezone( $bh->info->timezone )
      if $bh->info->timezone
          && !$entry->timezone;
    $entry->author( $self->author
          || Email::Address->new( $bh->info->name, $bh->info->email )->format )
      unless $entry->author;

    if ( $bh->create_entry( $entry, commit => 0, ) ) {
        $self->handle_attachments($entry);
        $bh->backend->commit( message => $self->message
              || 'created ' . $entry->id );
        puts "created " . $entry->id . ".";
    }
    else {
        die "failed to create the entry.";
    }
}

sub handle_attachments {
    my $self   = shift;
    my $parent = shift;
    return unless $self->attachments;
    for my $file ( @{ $self->attachments } ) {
        $file = decode( locale_fs => $file );
        if ( -f $file ) {

            require File::Basename;
            my $basename = File::Basename::basename($file);
            my $att      = Beagle::Model::Attachment->new(
                name         => $basename,
                content_file => $file,
                parent_id    => $parent->id,
            );

            handle->create_attachment( $att, commit => 0 );
        }
        else {
            die "$file is not a file or doesn't exist.";
        }
    }
}



1;

__END__

=head1 NAME

Beagle::Cmd::Command::create - create an entry

=head1 SYNOPSIS

    $ beagle create --type bark
    $ beagle bark                                   # ditto
    $ beagle create --type bark --verbose            # more fields to check/edit
    $ beagle create --type bark -a /path/to/att1 -a /path/to/att2
    $ beagle create --type bark --tags tv,simpsons
    $ beagle create --type bark --body doh --edit    # force to use editor

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

