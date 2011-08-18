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

    my $all  = roots();
    my $root = current_root('not die');
    my $current_name;
    if ($root) {
        ($current_name) = grep { $all->{$_}{local} eq $root } keys %$all;
    }

    my @names;

    if ( $self->all ) {
        @names = ( sort keys %$all );
    }
    elsif ( $self->names ) {
        @names = @{ to_array( $self->names ) };
    }
    elsif (@$args) {
        push @names, @$args;
    }
    elsif ( !$root ) {
        @names = ( sort keys %$all );
    }
    else {
        @names = root_name($root);
    }

    my $name_length = max_length(@names) + 1;
    $name_length = 5 if $name_length < 5;

    my $printed_current_root;

    if ( $self->verbose ) {
        require Text::Table;
        my $tb = Text::Table->new();

        if ( $root && !$current_name ) {
            if ( check_root($root) ) {
                $printed_current_root = 1;
                $tb->add( '@', 'external', root_type($root), $root, );
            }
        }

        for my $name (@names) {
            next unless $all->{$name};
            next if $printed_current_root;

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
    else {
        if ( $root && !$current_name ) {
            if ( check_root($root) ) {
                $printed_current_root = 1;
                puts $root;
            }
        }

        for my $name (@names) {
            next unless $all->{$name};
            next if $printed_current_root;
            my $root = name_root($name);
            puts $root if $root;
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

