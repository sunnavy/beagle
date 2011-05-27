package Beagle::Cmd::Command::spread;
use Any::Moose;
use Beagle::Util;
use Encode;
extends qw/Beagle::Cmd::Command/;

has 'cmd' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'spread cmd',
    traits        => ['Getopt'],
);

has 'dry-run' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'dry run',
    traits        => ['Getopt'],
    accessor      => 'dry_run',
);

has 'shorten' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'shorten url',
    traits        => ['Getopt'],
);

has 'quiet' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'not prompt for confirmation',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle spread --cmd spread-cmd id1 id2 [...]"
      unless @$args && $self->cmd;

    my $cmd = $self->cmd;
    for my $i (@$args) {
        my @ret = resolve_id( $i, handler => handler() || undef );
        unless (@ret) {
            @ret = resolve_id($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handler};
        my $entry = $ret[0]->{entry};

        my $msg;
        if ( $entry->type eq 'bark' ) {
            $msg = $entry->summary(70);
        }
        else {
            my $url = $bh->info->url . '/entry/' . $entry->id;
            if ( $self->shorten ) {
                my $s = `shorten $url`;
                chomp $s;
                die "shorten failed" unless $s && $s =~ /\S/;
                $url = $s;
            }
            $msg = join ' ', $entry->title, $url;
        }
        if ( $self->dry_run ) {
            puts "going to call `$cmd $msg`";
        }
        else {
            my $update = 1;
            if ( !$self->quiet ) {
                puts "going to call `$cmd $msg`";
                print "spread? (Y/n): ";
                my $val = <STDIN>;
                undef $update if $val =~ /n/i;
            }

            if ($update) {
                my @cmd = Text::ParseWords::shellwords($cmd);
                system( @cmd, $msg ) == 0 or die $!;
            }
        }
    }
}

sub usage_desc { "spread entries" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::spread - spread entries


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

