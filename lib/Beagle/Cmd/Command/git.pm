package Beagle::Cmd::Command::git;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has all => (
    isa           => 'Bool',
    is            => "rw",
    cmd_aliases   => 'a',
    documentation => "all",
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $cmd = shift @$args;
    die "beagle git cmd ..." unless $cmd;

    my @roots;

    if ( $self->all ) {
        my $all = beagle_roots();
        for my $name ( keys %$all ) {
            next unless $all->{$name}{type} eq 'git';
            if ( $all->{$name}{local} && $all->{$name}{remote} ) {
                push @roots, $all->{$name}{local};
            }
        }
    }
    else {
        my $root = beagle_root();
        die "$root is not of type git" unless root_type($root) eq 'git';

        @roots = $root;
    }

    if ( !@roots ) {
        CORE::die "please specify beagle by --name or --root\n";
    }

    $cmd =~ s!-!_!g;
    require Beagle::Git::Wrapper;

    for my $root (@roots) {
        my $git = Beagle::Git::Wrapper->new(
            root    => $root,
            verbose => $self->verbose,
        );
        puts root_name($root) . ':' unless @roots == 1;
        my ( $ret, $out ) = $git->$cmd(@$args);
        print $out if $ret;
    }
}

sub usage_desc { "bridge to git" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::git - bridge to git

=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

