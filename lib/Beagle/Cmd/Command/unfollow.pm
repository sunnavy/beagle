package Beagle::Cmd::Command::unfollow;
use Beagle::Util;
use Encode;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle unfollow name [...]" unless @$args;
    require File::Path;

    my @unfollowed;
    for my $name (@$args) {
        my $f_root = catdir( beagle_home_roots(), split /\//, $name );
        if ( -e $f_root ) {
            remove_tree($f_root);
        }

        for my $t ( '', '.drafts' ) {
            my $cache = catfile( beagle_home_cache(), cache_name($name), $t );
            remove_tree($cache) if -e $cache;
        }
        my $map = entry_map;
        for my $id ( keys %$map ) {
            delete $map->{$id} if $map->{$id} eq $name;
        }
        set_entry_map( $map );

        my $all = beagle_roots();
        if ( exists $all->{$name} ) {
            delete $all->{$name};
            set_beagle_roots($all);
        }
        push @unfollowed, $name;
    }

    puts "unfollowed ", join( ', ', @unfollowed ), '.';
}

sub usage_desc { "unfollow beagles" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::unfollow - unfollow beagles

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

