package Beagle::Test;
use strict;
use warnings;
use Beagle::Util;
use File::Temp 'tempdir';
use Test::More;
use File::Which 'which';
$ENV{BEAGLE_CACHE} = 0;
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

    my $pid = fork();
    die "failed to fork" unless defined $pid;

    my $port = 5000 + int rand 10_000;

    if ($pid) {
        push @pids, $pid;
        sleep 2;
        return "http://localhost:$port";
    }
    else {
        exec beagle_command(), qw/web -E deployment --port/, $port, @_;
        exit;
    }
}

sub beagle_command {
    my $class = shift;
    return which('beagle') || catfile( 'bin', 'beagle' );
}

END {
    kill 'TERM', @pids;
}

1;
__END__


=head1 AUTHOR

    sunnavy  C<< sunnavy@gmail.com >>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

