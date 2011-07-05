package Beagle::Cmd::Command::entry;
use Encode;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

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
    documentation => 'force',
    traits        => ['Getopt'],
);

has 'type' => (
    isa           => 'Str',
    is            => 'rw',
    cmd_aliases   => 't',
    documentation => 'type',
    traits        => ['Getopt'],
    required      => 1,
);

has author => (
    isa           => "Str",
    is            => "rw",
    documentation => "author",
    traits        => ['Getopt'],
);

has body => (
    isa           => "Str",
    is            => "rw",
    documentation => "body",
    traits        => ['Getopt'],
);

has 'body-file' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'body_file',
    documentation => "body file path",
    traits        => ['Getopt'],
);

has 'body-file-encoding' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'body_file_encoding',
    documentation => "body file encoding",
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => "Bool",
    is            => "rw",
    documentation => "edit with editor?",
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => "m",
    traits        => ['Getopt'],
);

sub class {
    my $self = shift;
    return 'Beagle::Model::' . ucfirst lc $self->type;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $root = beagle_root('not die');
    if ( !$root ) {
        CORE::die "please specify beagle by --name or --root\n";
    }

    require Beagle::Handle;
    my $bh = Beagle::Handle->new( root => $root );

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

    if (
        $bh->create_entry(
            $entry, message => $self->message || 'created ' . $entry->id
        )
      )
    {
        puts "created " . $entry->id . ".";
    }
    else {
        die "failed to create the entry.";
    }
}

sub usage_desc { "create a new entry" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::entry - create a new entry


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

