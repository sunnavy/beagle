package Beagle::Cmd::Command::web;
use Beagle::Util;
use Encode;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has admin => (
    isa           => "Bool",
    is            => "rw",
    documentation => "admin mode",
    traits        => ['Getopt'],
    default       => 0,
    lazy          => 1,
);

has all => (
    isa           => "Bool",
    is            => "rw",
    documentation => "enable all following beagles",
    traits        => ['Getopt'],
    default       => 0,
    cmd_aliases   => 'a',
    lazy          => 1,
);

has 'share-root' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'share_root',
    traits        => ['Getopt'],
    documentation => "specifiy this to overwrite Beagle::Web->share_root",
);

has 'command' => (
    isa           => 'Str',
    is            => 'rw',
    traits        => ['Getopt'],
    documentation => "command to run, e.g. plackup, starman, twiggy, etc.",
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $root = beagle_root('not die');
    if ( !$root && !$self->all ) {
        CORE::die "please specify beagle by --name or --root\n";
    }

    local $ENV{BEAGLE_NAME} = '';
    local $ENV{BEAGLE_ROOT} = $root;

    require Beagle::Web;
    my $share_root = $self->share_root || Beagle::Web->share_root();

    my $app = catfile( $share_root, 'app.psgi' );
    local $ENV{BEAGLE_WEB_ADMIN} =
      exists $self->{admin} ? $self->admin : Beagle::Web->enabled_admin();
    local $ENV{BEAGLE_ALL} =
      exists $self->{all} ? $self->all : $ENV{BEAGLE_ALL};

    require Plack::Runner;
    my $r = Plack::Runner->new;

    my @args;
    if ( $ENV{BEAGLE_WEB_OPT} ) {
        require Text::ParseWords;
        push @args, Text::ParseWords::shellwords( $ENV{BEAGLE_WEB_OPT} );
    }
    push @args, @$args;

    if ( $self->command ) {
        system( $self->command, $app, @args );
    }
    else {
        $r->parse_options(@args);
        $r->{server} ||= 'Standalone';
        $r->run($app);
    }
}

sub usage_desc { "start web server" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::web - start web server


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.
