package Beagle::Test;
use strict;
use warnings;
use Beagle::Util;
use File::Temp 'tempdir';
use Test::More;
use File::Which 'which';
$ENV{BEAGLE_CACHE} = 0;
$ENV{BEAGLE_ALL}   = 0;
delete $ENV{BEAGLE_NAME};
delete $ENV{BEAGLE_ROOT};

sub init_home {
    my $class = shift;
    my $home = tempdir( CLEANUP => 1 );
    $ENV{BEAGLE_HOME} = $home;
}

sub init {
    my $class = shift;

    my %args = @_;
    my $home = $class->init_home();
    my $root = tempdir( CLEANUP => 1 );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( Beagle::Util::create_beagle( type => 'fs', root => $root, @_ ),
        "created beagle $root" );
    $ENV{BEAGLE_ROOT} = $root;
    return wantarray ? ( $root, $home ) : $root;
}

my @pids;

sub start_server {
    my $class = shift;
    my %args  = @_;

    my $port = $class->find_port();

    my $started;
    local $SIG{USR1} = sub { $started = 1 };

    require Plack::Loader;
    my $server = Plack::Loader->load(
        'Standalone',
        port         => $port,
        server_ready => sub {
            kill 'USR1' => getppid();
        },
    );

    my $pid = fork();

    die "failed to fork" unless defined $pid;

    if ($pid) {
        push @pids, $pid;
        sleep 5 unless $started;
        return "http://localhost:$port";
    }
    else {
        require Beagle::Web;
        local $ENV{BEAGLE_WEB_ADMIN} = $ENV{BEAGLE_WEB_ADMIN};
        if ( exists $args{admin} ) {
            $ENV{BEAGLE_WEB_ADMIN} = $args{admin};
        }

        $server->run( Beagle::Web->app );
        exit;
    }
}

use Socket;

sub find_port {
    my $class = shift;
    my $port = shift || 5000 + int rand 10_000;

    my $socket;
    socket( $socket, PF_INET, SOCK_STREAM, getprotobyname('tcp') ) or die $!;

    my $addr = sockaddr_in( $port, INADDR_LOOPBACK );

    if ( connect( $socket, $addr ) ) {
        close $socket;
        return find_port( $port + 1 );
    }
    else {
        close $socket;
        return $port;
    }
}

sub beagle_command {
    my $class = shift;
    return which('beagle') || catfile( 'bin', 'beagle' );
}

sub stop_server {
    kill 'TERM', @pids if @pids;
}

END {
    stop_server();
}

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

