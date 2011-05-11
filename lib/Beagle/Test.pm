package Beagle::Test;
use strict;
use warnings;
use base 'Exporter';
use Beagle::Util;
use File::Temp 'tempdir';
use Test::More;
our @EXPORT = qw/create_tmp_beagle start_server/;

sub create_tmp_beagle {
    my $root = tempdir( CLEANUP => 1 );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( create_beagle( type => 'fs', root => $root, @_ ), "created beagle $root" );
    return $root;
}

my @pids;

sub start_server {
    my %args = @_;
    local $ENV{BEAGLE_ROOT} = create_tmp_beagle( type => 'git', @_ );

    my $pid = fork();
    die "failed to fork" unless defined $pid;

    my $port = 5000 + int rand 10_000;

    if ($pid) {
        push @pids, $pid;
        sleep 1;
        return ("http://localhost:$port", $ENV{BEAGLE_ROOT});
    }
    else {
        exec qw/beagle web -E deployment --port/, $port, @_;
        exit;
    }
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

