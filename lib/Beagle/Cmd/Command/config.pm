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
    isa           => "ArrayRef[Str]",
    is            => "rw",
    documentation => "set",
    traits        => ['Getopt'],
    default       => sub { [] },
);

has unset => (
    isa           => "ArrayRef[Str]",
    is            => "rw",
    documentation => "unset",
    traits        => ['Getopt'],
    default       => sub { [] },
);

has get => (
    isa           => "ArrayRef[Str]",
    is            => "rw",
    documentation => "show the specified config items",
    traits        => ['Getopt'],
    default       => sub { [] },
);

has 'get-all' => (
    isa           => "Bool",
    is            => "rw",
    documentation => "show all the config items",
    accessor      => "get_all",
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

        for my $key (qw/name email/) {
            print "user $key: ";
            chomp( my $val = <STDIN> );
            $core->{"user_$key"} = $val;
        }

        $core->{"default_command"} = 'shell';
        $core->{'cache'}           = 1;
        $core->{'devel'}           = 0;
        $core->{'web_admin'}       = 0;

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
        $updated = 1;
    }

    for my $name ( @{ $self->unset } ) {
        delete $core->{$name};
        $updated = 1 unless $updated;
    }

    set_core_config($core);

    puts "updated." if $updated;

    for my $name ( @{ $self->get } ) {
        puts join ': ', $name, defined $core->{$name} ? $core->{$name} : '';
    }

    if ( $self->get_all ) {
        for my $name ( sort keys %$core ) {
            puts join ': ', $name, defined $core->{$name} ? $core->{$name} : '';
        }
    }
}

sub usage_desc { "config beagle" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::config - config beagle

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

