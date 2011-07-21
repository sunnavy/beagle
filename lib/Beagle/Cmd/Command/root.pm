package Beagle::Cmd::Command::root;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

has all => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'a',
    documentation => 'all',
    traits        => ['Getopt'],
);

has 'names' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'show all names seperated by newlines',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $root = current_root('not die');

    my $all = roots();

    die "beagle root [name]" unless @$args <= 1;

    if ( $self->names ) {
        puts $_ for sort keys %$all;
        return;
    }

    if ( $self->all || !( @$args || $root ) ) {
        my $name_length = max_length( keys %$all ) + 1;
        $name_length = 5 if $name_length < 5;

        if ( keys %$all || $root ) {
            require Text::Table;
            my $tb = Text::Table->new();

            my $included_current;

            for my $name ( sort keys %$all ) {
                my $flag = '';
                if ( $root && $all->{$name}{local} eq $root ) {
                    $flag = '@';
                    $included_current = 1;
                }

                $tb->add(
                    $flag, $name,
                    $all->{$name}{type} || 'git',
                    $all->{$name}{remote},
                );
            }

            if ( $root && !$included_current ) {
                $tb->add( '@', 'external', root_type($root), $root );
            }

            puts $tb;
        }
    }
    else {
        my ( $local_root, $remote_root, $name, $type );
        if ( $name = $args->[0] ) {
            if ( $all->{$name} ) {
                $local_root  = $all->{$name}{local};
                $remote_root = $all->{$name}{remote};
                $type        = $all->{$name}{type} || 'git';
            }
            else {
                die qq{$name doesn't exist.};
            }
        }

        if ($root) {
            unless ( $name && $local_root ) {
                for my $n ( keys %$all ) {
                    if ( $all->{$n}{local} eq $root ) {
                        $name        = $n;
                        $local_root  = $all->{$n}{local};
                        $remote_root = $all->{$n}{remote};
                        $type        = $all->{$name}{type} || 'git';
                        last;
                    }
                }
            }

            unless ($local_root) {
                $local_root = $remote_root = $root;
                if ( -e catdir( $root, '.git' ) ) {
                    $type = 'git';
                }
                else {
                    $type = 'fs';
                }
                $name = '_';
            }
        }

        die "root not found" unless $local_root;

        if ( $self->verbose ) {
            my $name_length = length($name) + 1;
            $name_length = 5 if $name_length < 5;

            require Text::Table;
            my $tb = Text::Table->new();
            $tb->add( $name, $type, $remote_root );
            puts $tb;
        }
        else {
            puts $local_root;
        }
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::root - show root

=head1 SYNOPSIS

    $ beagle root

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

