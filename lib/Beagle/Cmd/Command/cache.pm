package Beagle::Cmd::Command::cache;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "cache for all the beagles",
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

has 'update' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "update",
    cmd_aliases   => 'u',
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "force update",
    cmd_aliases   => 'f',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my @roots;
    my $root = beagle_root('not die');

    my $all = beagle_roots();
    if ( $self->all || !$root ) {
        for my $name ( keys %$all ) {
            push @roots, $all->{$name}{local};
        }
    }
    else {
        @roots = $root;
    }

    if ( $self->update ) {
        for my $root (@roots) {
            require Beagle::Handler;

            if ( $self->force ) {
                my $name = root_name($root);
                $name =~ s!\W!_!g;
                unlink catfile( beagle_home_cache(), $name . '.drafts' );
                unlink catfile( beagle_home_cache(), $name );
            }

            Beagle::Handler->new( root => $root, drafts => 0 );
            Beagle::Handler->new( root => $root, drafts => 1 );
        }
        puts 'updated cache.';
    }
    else {
        return unless @roots;

        my $name_length = max_length( keys %$all ) + 1;
        $name_length = 5 if $name_length < 5;

        require Text::Table;
        my $tb = Text::Table->new( qw/name with_drafts normal/ );

        for my $root (@roots) {

            # Beagle::Handler->new will update cache for us
            require Storable;
            require Beagle::Handler;

            my %info;
            require Beagle::Backend;
            my $backend = Beagle::Backend->new( root => $root, );
            my $latest = $backend->updated;

            for my $p ( '', '.drafts' ) {
                my $name = root_name($root);
                $name =~ s![/\\]!_!g;
                my $file = catfile( beagle_home(), 'cache', "$name$p" );
                my $type = $p ? 'drafts' : 'normal';
                if ( -e $file ) {
                    my $bh = Storable::retrieve($file);
                    if ( $bh->updated < $latest ) {
                        $info{$type} = 'outdated';
                    }
                    else {
                        $info{$type} = 'latest';
                    }

                    $info{$type} .= '(' . pretty_datetime( $bh->updated ) . ')';
                }
                else {
                    $info{$type} = 'none';
                }
            }

            $tb->add( root_name($root), $info{drafts}, $info{normal} );
        }
        puts $tb;
    }
}

sub usage_desc { "manage cache" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::cache - manage cache


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

