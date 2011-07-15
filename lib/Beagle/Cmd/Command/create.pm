package Beagle::Cmd::Command::create;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has bare => (
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "b",
    documentation => "bare git repo",
    traits        => ['Getopt'],
);

has force => (
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "force to create",
    traits        => ['Getopt'],
);

has type => (
    isa           => "BackendType",
    is            => "rw",
    documentation => "type of the backend",
    traits        => ['Getopt'],
    default       => 'git',
);

has name => (
    isa           => 'Str',
    is            => 'rw',
    cmd_aliases   => 'n',
    documentation => 'beagle name, will create it in $BEAGLE_KENNEL/roots directly',
    traits        => ['Getopt'],
);

has 'edit' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "use editor",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    die "can't specify --bare with --name" if $self->name && $self->bare;
    die "can't specify --root with --name"   if $self->name && @$args;
    die "need root" unless @$args || $self->name;

    my $root =
      rel2abs( $args->[0]
          || catdir( backends_root(), split /\//, $self->name ) );

    if ($root) {
        if ( -e $root ) {
            if ( $self->force ) {
                remove_tree($root);
            }
            else {
                die "$root already exists, use --force|-f to override";
            }
        }
    }
    make_path($root) or die "failed to create $root";

    my $info;
    if ( $self->edit ) {
        require Beagle::Model::Info;
        my $template = Beagle::Model::Info->new()->serialize;
        my $updated = edit_text($template);
        $info = Beagle::Model::Info->new_from_string( decode_utf8 $updated);
    }

    # $opt->{name} is not user name but beagle name
    create_backend( %$opt, root => $root, info => $info, name => undef );

    if ( $self->name ) {
        my $all = roots();

        $all->{$self->name} = {
            local => $root,
            type  => $self->type,
        };

        set_roots($all);
        puts "created."
    }
    else {
        puts
"created, please run `beagle follow $root --type @{[$self->type]}` to continue.";
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::create - create a beagle

=head1 SYNOPSIS

    $ beagle create --name foo          # create an internal beagle in the kennel
    $ beagle create /path/to/foo.git --bare

=head1 DESCRIPTION

Usually, you want to create a external git repo and then C<follow> it, using
C<--name> will create an internal git repo and you won't be able to C<push>
and C<pull> easily.

We suppot plain file system as backend via C<--type fs>, you don't want to do
this usually as it doesn't support version control at all.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

