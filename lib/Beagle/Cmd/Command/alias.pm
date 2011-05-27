package Beagle::Cmd::Command::alias;
use Beagle::Util;
use Encode;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has set => (
    isa           => "Bool",
    is            => "rw",
    documentation => "set",
    traits        => ['Getopt'],
);

has unset => (
    isa           => "Bool",
    is            => "rw",
    documentation => "unset",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $system_alias = system_alias;
    my $user_alias   = user_alias;
    my $alias = alias;

    if ( $self->set || $self->unset ) {

        if ( $self->set ) {
            for my $item (@$args) {
                my ( $name, $value ) = split /=/, $item, 2;
                $user_alias->{$name} = $value;
            }
        }
        elsif ( $self->unset ) {
            for my $name (@$args) {
                delete $user_alias->{$name};
            }
        }
        set_user_alias($user_alias);
        puts "updated.";
        return;
    }

    if (@$args) {
        for my $key (@$args) {
            my $value = $alias->{$key};
            puts "$key: $value";
        }
    }
    else {

        my $width = max_length( keys %{$alias} );
        $width += 2;

        puts "System aliases:";
        for my $cmd ( sort keys %$system_alias ) {
            printf "%${width}s: %s" . newline, $cmd, $system_alias->{$cmd};
        }
        puts;

        if ( keys %$user_alias ) {
            puts "Personal aliases:";
            for my $cmd ( sort keys %$user_alias ) {
                printf "%${width}s: %s" . newline, $cmd, $user_alias->{$cmd};
            }
            puts;
        }
    }
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::alias - show command alias(es)

=head1 AUTHOR

    sunnavy  <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

