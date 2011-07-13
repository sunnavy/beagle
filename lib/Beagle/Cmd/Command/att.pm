package Beagle::Cmd::Command::att;
use Encode;
use Beagle::Util;
use Any::Moose;
use File::Basename;

extends qw/Beagle::Cmd::Command/;

has 'parent' => (
    isa           => "Str",
    is            => "rw",
    documentation => "parent id",
    cmd_aliases   => 'p',
    traits        => ['Getopt'],
);

has prune => (
    isa           => "Bool",
    is            => "rw",
    documentation => "remove attachments of which parent doesn't exist",
    traits        => ['Getopt'],
);

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "all the beagles",
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

sub command_names { qw/att attachment attachments/ };

sub execute {
    my ( $self, $opt, $args ) = @_;
    require Beagle::Handle;
    my $pid = $self->parent;

    my $subcmd;
    if ( @$args && $args->[0] =~ /^(?:cat|show|ls|list|add|rm|delete)$/ ) {
        $subcmd = shift @$args;
    }
    else {
        $subcmd = @$args ? 'cat' : 'ls';
    }

    require Beagle::Handle;
    my $bh;

    if ( $pid ) {
        my @ret = resolve_entry( $pid, handle => handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($pid) or die_entry_not_found($pid);
        }
        die_entry_ambiguous( $pid, @ret ) unless @ret == 1;
        $pid = $ret[0]->{id};
        $bh = $ret[0]->{handle};
    }

    if ( $subcmd eq 'add' ) {
        die "beagle att add --parent foo /path/to/a.txt [...]" unless $pid;
        my @added;
        for my $file (@$args) {
            if ( -f $file ) {
                my $basename = decode_utf8 basename $file;
                my $att      = Beagle::Model::Attachment->new(
                    name         => $basename,
                    content_file => $file,
                    parent_id    => $pid,
                );
                if ( $bh->create_attachment( $att, commit => 0, ) ) {
                    push @added, $basename;
                }
                else {
                    die "failed to create attachment $file.";
                }
            }
            else {
                die "$file is not a file or doesn't exist";
            }
        }

        if (@added) {
            my $msg = $self->message
              || 'added attachment' . ( @add == 1 ? ' ' : 's ' ) . join( ',
              ', @added ) . " to entry $pid";
            $bh->backend->commit( message => $msg );
            puts 'added ', join( ', ', @added ), '.';
        }
        return;
    }

    my %handle_map;


    my @att;
    if ($pid) {
        my $map = $bh->attachments_map->{$pid};
        @att = sort values %$map;
    }
    else {
        my @bh = $self->all ? handles() : ( handle || handles );

        for my $bh (@bh) {
            $handle_map{ $bh->root } = $bh;
            for ( keys %{ $bh->attachments_map } ) {
                unless ( $bh->map->{$_} ) {
                    if ( $self->prune ) {
                        my $dir = catdir( 'attachments', split_id($_) );
                        if ( -e catdir( $bh->root, $dir ) ) {
                            $bh->backend->delete( undef, path => $dir )
                              or die "failed to delete $dir: $!";
                        }
                    }
                    else {
                        warn
"article $_ doesn't exist, run 'att --prune' can clean it out"
                          unless $bh->map->{$_};
                    }
                }

            }

            for my $entry (
                sort {
                        $bh->map->{$a}
                      ? $bh->map->{$b}
                          ? $bh->map->{$b}->created <=> $bh->map->{$a}->created
                          : -1
                      : 1
                }
                sort keys %{ $bh->attachments_map }
              )
            {
                push @att, sort values %{ $bh->attachments_map->{$entry} };
            }
        }
    }

    if ( $subcmd =~ /^(?:delete|rm)$/ ) {
        die "beagle att rm 3 [...]" unless @$args;
        my @deleted;

        # before deleting anything, let's make sure no invliad index
        for my $i (@$args) {
            die "$i is not a number" unless $i =~ /^\d+$/;
            die "no such attachment with index $i" unless $att[ $i - 1 ];
        }

        for my $i (@$args) {
            my $att = $att[ $i - 1 ];
            my $handle = $bh || $handle_map{ $att->root };
            if ( $handle->delete_attachment( $att, commit => 0 ) ) {
                push @deleted, { handle => $handle, name => $att->name };
            }
            else {
                die "failed to delete attachment $i: " . $att->name . ".";
            }
        }

        if (@deleted) {
            my @handles = uniq map { $_->{handle} } @deleted;
            for my $bh (@handles) {
                my $msg = 'deleted '
                  . join( ', ',
                    map { $_->{name} }
                    grep { $_->{handle}->root eq $bh->root } @deleted );
                $bh->backend->commit( message => $self->message || $msg );
            }
            my $msg = 'deleted ' . join( ', ', map { $_->{name} } @deleted );
            puts $msg . '.';
        }
        return;
    }

    if ( $subcmd =~ /^(?:show|cat)$/ ) {
        die "beagle att cat 3 [...]" unless @$args;

        my $first = 1;

        for my $i (@$args) {
            die "$i is not a number" unless $i =~ /^\d+$/;
            die "no such attachment with index $i" unless $att[ $i - 1 ];
        }

        for my $i (@$args) {
            puts '=' x term_width() unless $first;
            undef $first if $first;
            my $att = $att[ $i - 1 ];
            binmode *STDOUT;
            print $att->content;
        }
    }
    else {
        return unless @att;

        die "beagle att ls [--parent foo]" if @$args;

        my $name_length = max_length( map { $_->name } @att ) + 1;
        $name_length = 10 if $name_length < 10;

        require Text::Table;
        my $tb =
          $self->verbose
          ? Text::Table->new( qw/index parent size name/, )
          : Text::Table->new();

        for ( my $i = 1 ; $i <= @att ; $i++ ) {
            my $att  = $att[ $i - 1 ];
            my $name = $att->name;
            $tb->add( $i, ( $self->verbose ? ( $att->parent_id ) : () ),
                $att->size, $att->name );

        }
        puts $tb;
    }
}

sub usage_desc { "manage attachments" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::att - manage attachments


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

