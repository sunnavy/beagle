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
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $all = roots();
    my $root = current_root('not die');
    my ($current_name) = grep { $all->{$_}{local} eq $root } keys %$all;

    die "beagle root [name]" unless @$args <= 1;

    my @names;
    if ( $self->all || $self->names || !$root ) {

        if ( $self->all ) {
            @names = ( sort keys %$all );
        }
        elsif ( $self->names ) {
            @names = @{ to_array( $self->names ) };
        }
        else {
            @names = ( sort keys %$all );
        }

        my $name_length = max_length(@names) + 1;
        $name_length = 5 if $name_length < 5;

        if ( $self->verbose ) {
            if (@names || $root ) {
                require Text::Table;
                my $tb = Text::Table->new();

                if ( $self->all && $root && !$current_name ) {
                    $tb->add( '@', 'external', root_type($root), $root, );
                }

                for my $name (@names) {
                    next unless $all->{$name};
                    my $flag = '';
                    if ( $root && $all->{$name}{local} eq $root ) {
                        $flag = '@';
                    }

                    $tb->add(
                        $flag, $name,
                        $all->{$name}{type} || 'git',
                        $all->{$name}{remote},
                    );
                }

                puts $tb;
            }
        }
        else {
            if ( $self->all && $root && !$current_name ) {
                puts $root;
            }

            for my $name (@names) {
                puts name_root($name);
            }
        }
    }
    else {
        my $name = $current_name;
        if ( $self->verbose ) {
            require Text::Table;
            my $tb = Text::Table->new();

            if ($name) {
                $tb->add(
                    $name,
                    $all->{$name}{type} || 'git',
                    $all->{$name}{remote},
                );
            }
            else {
                $tb->add( '@', 'external', root_type($root), $root );
            }
            puts $tb;
        }
        else {
            puts $root;
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

