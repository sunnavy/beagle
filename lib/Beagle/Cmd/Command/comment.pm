package Beagle::Cmd::Command::comment;
use Encode;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

has 'parent' => (
    isa           => "Str",
    is            => "rw",
    documentation => "parent id",
    cmd_aliases   => 'p',
    traits        => ['Getopt'],
);

has author => (
    isa           => "Str",
    is            => "rw",
    documentation => "author",
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'f',
    documentation => 'force',
    traits        => ['Getopt'],
);

has 'message' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'message to commit',
    cmd_aliases   => "m",
    traits        => ['Getopt'],
);


no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    require Email::Address;

    my $pid = $self->parent;
    die "beagle comment --parent parent_id ..." unless $pid;

    my @ret = resolve_id( $pid, handler => handler() || undef );
    unless (@ret) {
        @ret = resolve_id($pid) or die_entry_not_found($pid);
    }
    die_entry_ambiguous( $pid, @ret ) unless @ret == 1;
    $pid = $ret[0]->{id};
    my $bh = $ret[0]->{handler};

    my $author = $self->author
      || Email::Address->new( $bh->info->name, $bh->info->email )->format;

    my $body = join ' ', @$args;

    my $comment;

    unless ( $body =~ /\S/ ) {
        my $temp = Beagle::Model::Comment->new();
        $temp->timezone( $bh->info->timezone ) if $bh->info->timezone;
        my $template =
          $self->verbose
          ? $temp->serialize(
            path      => 1,
            created   => 1,
            updated   => 1,
            id        => 1,
            parent_id => 1,
          )
          : $temp->serialize_body($body);
        my $updated = edit_text($template);
        if ( !$self->force && $template eq $updated ) {
            puts "aborted.";
            return;
        }

        $comment =
          Beagle::Model::Comment->new_from_string( decode_utf8 $updated );
        unless ( $self->verbose ) {
            $comment->id( $temp->id );
            $comment->parent_id($pid);
            $comment->created( $temp->created );
            $comment->updated( $temp->updated );
        }
    }
    else {
        $comment = Beagle::Model::Comment->new( body => $body, );
    }

    $comment->parent_id($pid);
    $comment->author($author) if $author;
    $comment->timezone( $bh->info->timezone ) if $bh->info->timezone;
    if (
        $bh->create_entry(
            $comment, message => $self->message || 'created ' . $comment->id
        )
      )
    {
        puts "created " . $comment->id . ".";
    }
    else {
        die "failed to create the comment.";
    }
}

sub usage_desc { "create a new comment" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::comment - create a new comment


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

