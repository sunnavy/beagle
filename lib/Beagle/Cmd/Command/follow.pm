package Beagle::Cmd::Command::follow;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has name => (
    isa           => "Str",
    is            => "rw",
    documentation => "name of following",
    traits        => ['Getopt'],
);

has depth => (
    isa           => "Num",
    is            => "rw",
    documentation => "depth of repo to be named",
    traits        => ['Getopt'],
    default       => 0,
);

has force => (
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "force to follow",
    traits        => ['Getopt'],
);

has type => (
    isa           => "BackendType",
    is            => "rw",
    documentation => "type of the backend",
    traits        => ['Getopt'],
    default       => 'git',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle follow repo_uri1 [...]" unless @$args;
    die "can't follow multiple beagles with --name"
      if @$args > 1 && $self->name;

    my $name  = $self->name;
    my $depth = $self->depth;
    for my $root (@$args) {

        $depth = 0 unless $depth > 0;

        if ( !$name ) {
            $root =~ m{(([^/]+/){$depth}[^/]+)$};
            $name = $1 or die "can't resolve the name";
            $name =~ s/\.git$//;
        }

        my $f_root = catdir( backend_root(), split /\//, $name );
        if ( -e $f_root ) {
            if ( $self->force ) {
                remove_tree($f_root);
            }
            else {
                die "$f_root already exists, use -f or --force to overwrite";
            }
        }

        my $parent = parent_dir($f_root);
        make_path($parent) or die "failed to create $parent" unless -d $parent;

        if ( $self->type eq 'git' ) {
            require Beagle::Wrapper::git;
            my $git = Beagle::Wrapper::git->new( verbose => $self->verbose );

            my $default    = core_config;
            my $user_name  = $default->{user_name};
            my $user_email = $default->{user_email};

            my ( $ret, $out ) = $git->clone( $root, $f_root );
            die "failed to clone $root: $out" unless $ret;
            $git->root($f_root);
            if ($user_name) {
                $git->config( '--add', 'user.name', $user_name );
            }
            if ($user_email) {
                $git->config( '--add', 'user.email', $user_email );
            }
        }
        elsif ( $self->type eq 'fs' ) {
            require File::Copy::Recursive;
            File::Copy::Recursive::dircopy( $root, $f_root );
        }

        my $all = roots();

        $all->{$name} = {
            remote => $root,
            local  => catdir( backend_root(), split /\//, $name ),
            type   => $self->type,
        };

        set_roots($all);

        puts "followed $root.";
    }
}

sub usage_desc { "follow beagles" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::follow - follow beagles

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

