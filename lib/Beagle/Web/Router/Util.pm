package Beagle::Web::Router::Util;
use Router::Simple;
use base 'Exporter';

our @EXPORT = qw/bh req render get post any new_router/;
sub bh     { Beagle::Web->current_handle() }
sub req    { Beagle::Web->current_request() }
sub render { goto \&Beagle::Web::render }

sub new_router {
    my $router = Router::Simple->new();
    my $admin  = $router->submapper(
        '/admin',
        {},
        {
            on_match => sub {
                return Beagle::Web->enabled_admin() ? 1 : 0;
            },
        }
    );
    return ( $router, $admin );
}

sub router_package {
    my $package;
    for my $i ( 1 .. 10 ) {
        my $p = ( caller($i) )[0];
        if ( $p && $p =~ /::Router$/ ) {
            $package = $p;
        }
    }
    die "failed to find router package" unless $package;
    return $package;
}

sub any {
    my $methods;
    $methods = shift if @_ == 3;

    my $pattern = shift;
    my $code    = shift;
    my $dest    = { code => $code };
    my $opt     = { $methods ? ( method => $methods ) : () };

    my ( $router, $admin ) = router_package()->router;

    if ( $pattern =~ s{^/admin(?=/)}{} ) {
        $admin->connect( $pattern, $dest, $opt );
    }
    else {
        $router->connect( $pattern, $dest, $opt, );
    }
}

sub get {
    any( [qw/GET HEAD/], $_[0], $_[1] );
}

sub post {
    any( [qw/POST/], $_[0], $_[1] );
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


