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
    documentation => "initialize config items",
    traits        => ['Getopt'],
);

has set => (
    isa           => "ArrayRef[Str]",
    is            => "rw",
    documentation => "set config items",
    traits        => ['Getopt'],
);

has unset => (
    isa           => "ArrayRef[Str]",
    is            => "rw",
    documentation => "delete config items",
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

        $core->{"default_command"} = 'shell';
        $core->{'cache'}           = 1;
        $core->{'devel'}           = 0;
        $core->{'web_admin'}       = 0;

        if ( $self->set ) {
            for my $item ( @{ $self->set } ) {
                my ( $name, $value ) = split /=/, $item, 2;
                $core->{$name} = $value;
            }
        }

        if ( $self->unset ) {
            for my $key ( @{ $self->unset } ) {
                delete $core->{$key};
            }
        }

        for my $key (qw/name email/) {
            next if $core->{"user_$key"};
            print "user $key: ";
            chomp( my $val = <STDIN> );
            $core->{"user_$key"} = $val;
        }

        set_core_config($core);

        # check if there are roots already
        my $old = detect_beagle_roots();
        set_beagle_roots($old);

        puts "initialized.";
        puts "now add etc/bashrc to your .bashrc.";
        puts
"if you use bash's completion, add etc/completion/bash to your .bashrc.";
        puts
"if you use oh-my-zsh, copy etc/completion/zsh/beagle to oh-my-zsh/plugins/, then add beagle to plugins in your .zshrc.";
        return;
    }

    my $updated;
    for my $item ( @{ $self->set } ) {
        my ( $name, $value ) = split /=/, $item, 2;
        $core->{$name} = $value;
        $updated = 1 unless $updated;
    }

    for my $key ( @{ $self->unset } ) {
        delete $core->{$key};
        $updated = 1 unless $updated;
    }

    if ( $updated ) {
        set_core_config($core);
        puts 'updated.';
    }
    else {
        puts 'no changes.';
    }
}

sub usage_desc { "configure beagle" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::config - configure beagle

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

