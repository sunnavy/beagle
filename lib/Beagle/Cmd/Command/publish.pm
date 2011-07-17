package Beagle::Cmd::Command::publish;
use Any::Moose;
use Beagle::Util;
use Encode;
use File::Copy::Recursive 'dircopy';

extends qw/Beagle::Cmd::Command/;

has 'to' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'directory to publish to',
    traits        => ['Getopt'],
);

has 'force' => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => "f",
    documentation => 'remove the path if it exists already',
    traits        => ['Getopt'],
);

has 'drafts' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'including drafts too',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

my $app;
my $handle;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die 'beagle publish --to /path/to' unless defined $self->to;
    my @bh;
    for my $name (@$args) {
        require Beagle::Handle;
        push @bh,
          Beagle::Handle->new(
            root   => name_root($name),
            drafts => ( $self->drafts ? 1 : 0 ),
          );
    }

    unless (@bh) {
        @bh = handle( '', drafts => ( $self->drafts ? 1 : 0 ) )
          or die "please specify beagle by --name or --root";
    }

    require Beagle::Web;
    require Beagle::Web::Router;
    $app = \&Beagle::Web::Router::handle_request;

    for my $bh (@bh) {
        $handle = $bh;
        my $to = catdir( $self->to, $bh->name );
        my $encoded_to = encode( locale_fs => $to );
        if ( -e $encoded_to ) {
            if ( $self->force ) {
                remove_tree($encoded_to);
            }
            else {
                die "$encoded_to already exists, use --force|-f to override";
            }
        }

        make_path($encoded_to);

        chdir $encoded_to;

        my $system = encode( locale_fs => catdir( share_root(), 'public' ) );
        dircopy( $system, 'system' );

        my $static = encode( locale_fs => static_root($bh) );
        dircopy( $static, 'static' );

        Beagle::Web::Router::change_handle( handle => $bh );
        Beagle::Web::Router::set_prefix('');

        save_link( '/', 'index.html' );
        save_link( '/about', );
        save_link( '/feed' );

        my $entries = $bh->entries;
        for my $entry ( @$entries ) {
            save_link( '/entry/' . $entry->id );
        }

        for my $tag ( keys %{Beagle::Web::tags($bh)} ) {
            save_link("/tag/$tag");
        }

        for my $year ( keys %{Beagle::Web::years($bh)} ) {
            save_link("/date/$year");
        }
    }
}


sub save_link {
    my $link = shift or die 'need a link';
    my $file = shift;
    $file = $link unless defined $file;
    $file =~ s!^/!!;
    $file = encode( locale_fs => catfile( split m{/}, $file ) );

    my $res = $app->(
        {
            'PATH_INFO'      => $link,
            'REQUEST_METHOD' => 'GET',
            'BEAGLE_NAME'    => $handle->name,
        }
    );
    die "failed to get $link: " if $res->[0] != 200;
    my $parent = parent_dir($file);
    make_path($parent) unless -e $parent;
    write_file( $file, $res->[2] );
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::publish - publish beagles

=head1 SYNOPSIS

    $ beagle publish --to /path/to/dir name1 name2

=head1 DESCRIPTION

C<publish> is used to generate static html files so you can serve them
statically.

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

