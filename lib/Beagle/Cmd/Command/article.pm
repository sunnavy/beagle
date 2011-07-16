package Beagle::Cmd::Command::article;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::Command::create/;

has 'type' => (
    isa     => 'Str',
    is      => 'ro',
    default => 'article',
);

has title => (
    isa           => "Str",
    is            => "rw",
    documentation => "title",
    traits        => ['Getopt'],
);


no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $bh = handle() or die "please specify beagle by --name or --root";

    $opt->{tags} = to_array( delete $opt->{tags} );

    my $article;
    my $edit = delete $opt->{edit};

    $opt->{body} = join ' ', @$args if @$args && !defined $opt->{body};

    if ( $opt->{title} && $opt->{body} && !$edit ) {
        $article = $self->class->new(
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
        my $template = encode_utf8 $temp->serialize(
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

        $article = $self->class->new_from_string( decode_utf8 $updated);
        unless ( $self->verbose ) {
            $article->id( $temp->id );
            $article->created( $temp->created );
            $article->updated( $temp->updated );
        }
    }

    $article->timezone( $bh->info->timezone ) if $bh->info->timezone;
    $article->author( $self->author
          || Email::Address->new( $bh->info->name, $bh->info->email )->format )
      unless $article->author;
    if ( $bh->create_entry( $article, commit => 0, ) ) {
        $self->handle_attachments($article);
        $bh->backend->commit( message => $self->message
              || 'created ' . $article->id );
        puts "created " . $article->id . ".";
    }
    else {
        die "failed to create the article.";
    }

}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::article - create an article

=head1 SYNOPSIS

    $ beagle article # editor will pop up if without --title and --body
    $ beagle article --title homer --body doh
    $ beagle article --title homer --body doh --edit # use an editor anyway

checkout C<entry> command to find more examples.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

