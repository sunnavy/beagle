package Beagle::Web::Router::Util;
use Router::Simple;
use base 'Exporter';
our @EXPORT = qw/bh req render get post any router admin/;
sub bh     { Beagle::Web->current_handle() }
sub req    { Beagle::Web->current_request() }
sub render { goto \&Beagle::Web::render }

sub router {
    my $class = shift || router_package();
    no strict 'refs';
    return ${"${class}::ROUTER"};
}

sub admin {
    my $class = shift || router_package();
    no strict 'refs';
    return ${"${class}::ADMIN"};
}

sub import {
    init();
    __PACKAGE__->export_to_level(1, @_);
}

sub init {
    my $pkg = router_package();
    no strict 'refs';
    ${"${pkg}::ROUTER"} ||= Router::Simple->new();
    ${"${pkg}::ADMIN"}  ||= ${"${pkg}::ROUTER"}->submapper(
        '/admin',
        {},
        {
            on_match => sub {
                return Beagle::Web->enabled_admin() ? 1 : 0;
            },
        }
    );
}

sub router_package {
    my $pkg;
    for my $i ( 1 .. 10 ) {
        my $p = ( caller($i) )[0];
        if ( $p && $p =~ /::Router$/ ) {
            $pkg = $p;
        }
    }
    die "failed to find router package" unless $pkg;
    return $pkg;
}

sub any {
    my $methods;
    $methods = shift if @_ == 3;

    my $pattern = shift;
    my $code    = shift;
    my $dest    = { code => $code };
    my $opt     = { $methods ? ( method => $methods ) : () };

    my $router = router_package()->router;
    my $admin = router_package()->admin;

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


