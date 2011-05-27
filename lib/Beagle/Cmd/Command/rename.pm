package Beagle::Cmd::Command::rename;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

has force => (
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "force to rename",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle rename old_name new_name" unless @$args == 2;

    my ( $old_name, $new_name ) = @$args;
    die "new name is equal to the old name." if $old_name eq $new_name;

    my $all = beagle_roots();
    die "$old_name doesn't exist" unless $all->{$old_name};

    $all->{$new_name} = delete $all->{$old_name};

    my $old_path = catdir( beagle_home_roots(), split qr{/}, $old_name );
    my $new_path = catdir( beagle_home_roots(), split qr{/}, $new_name );
    $all->{$new_name}{local} = $new_path;

    if ( -e $new_path ) {
        die "$new_path already exists, use --force|-f to override"
          unless $self->force;
        remove_tree($new_path) or die "failed to remove $new_path: $!";
    }

    my $new_parent = parent_dir( $new_path );
    make_path( $new_parent ) unless -e $new_parent;

    rename( $old_path, $new_path )
      or die "failed to move $old_path to $new_path: $!";

    my $old_parent = parent_dir( $old_path );
    opendir my $dh, $old_parent or die $!;
    unless ( grep { $_ ne '.' && $_ ne '..' } readdir $dh ) {
        remove_tree($old_parent)
          or warn "failed to remove empty $old_parent: $!";
    }

    set_beagle_roots($all);

    puts "renamed $old_name to $new_name.";
}

sub usage_desc { "rename a beagle" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::rename - rename a beagle

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

