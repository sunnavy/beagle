package Beagle::Cmd::Command::config;
use Beagle::Util;
use Any::Moose;
use Encode;
extends qw/Beagle::Cmd::GlobalCommand/;

has force => (
    isa           => "Bool",
    is            => "rw",
    documentation => "force",
    cmd_aliases   => 'f',
    traits        => ['Getopt'],
);

has init => (
    isa           => "Bool",
    is            => "rw",
    documentation => "initialize",
    traits        => ['Getopt'],
);

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

    my $core = core_config();

    if ( $self->init ) {
        if ( keys %$core && !$self->force ) {
            die
              "default is initialized already, use --force|-f to overwrite.\n";
        }
        for my $key (qw/cache devel/) {
            print "enable $key(Y/n): ";
            my $val = <STDIN>;
            $core->{$key} = $val =~ /n/i ? 0 : 1;
        }

        for my $key (qw/name email/) {
            print "user $key: ";
            chomp( my $val = <STDIN> );
            $core->{"user_$key"} = $val;
        }

        $core->{"command"} = 'shell';

        set_core_config($core);

        # check if there are roots already
        my $old = detect_beagle_roots();
        set_beagle_roots($old);

        puts "initialized.";
        return;
    }

    if ( $self->set || $self->unset ) {

        if ( $self->set ) {
            for my $item (@$args) {
                my ( $name, $value ) = split /=/, $item, 2;
                $core->{$name} = $value;
            }
        }
        elsif ( $self->unset ) {
            for my $name (@$args) {
                delete $core->{$name};
            }
        }
        set_core_config($core);
        puts "updated.";
    }
    else {
        if (@$args) {
            for my $name (@$args) {
                puts join ': ', $name,
                  defined $core->{$name} ? $core->{$name} : '';
            }
        }
        else {
            for my $name ( sort keys %$core ) {
                puts join ': ', $name,
                  defined $core->{$name} ? $core->{$name} : '';
            }
        }
    }
}

sub usage_desc { "config beagle" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::config - config beagle

=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

