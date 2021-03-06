package Beagle::Cmd::Command::shell;
use Beagle::Util;

use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has 'spawn' => (
    isa           => 'Bool',
    is            => 'rw',
    traits        => ['Getopt'],
    documentation => 'spawn for each cmd',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;
sub command_names { qw/shell sh/ };

sub prompt {
    root_name() . '> ';
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    die "can't call shell command in web term" if $ENV{BEAGLE_WEB_TERM};

    local $| = 1;
    require Term::ReadLine;
    my $term = Term::ReadLine->new('Beagle');

    my $attribs = $term->Attribs;
    $attribs->{completion_function} = sub {
        my ( $text, $line, $start ) = @_;
        if ( $line !~ /\w+\s+/ ) {
            return ( aliases,
                qw/which use switch/,
                map { ( $_->command_names )[0] } $self->app->command_plugins
            );
        }

        if ( $line =~
            /(^|\s+)(--name|-n|--unfollow|use|switch|rename|root)\s+\w*$/ )
        {
            return sort keys %{ roots() };
        }

        if ( $line =~ /^help\s+\w*$/ ) {
            return
              sort map { ( $_->command_names )[0] } $self->app->command_plugins;
        }

        if ( $line =~ /\s+((?:\S|(?:\\\s))+)$/ ) {
            my $part = $1;
            my $dir = -d $part ? $part : parent_dir($part);
            opendir my $dh, $dir or return;
            return map {
                -d catdir( $dir, $_ )
                  ? catdir( $dir, $_ )
                  : catdir( $dir, $_ )
            } grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        }
        else {
            require Cwd;
            opendir my $dh, Cwd::getcwd or return;
            return grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        }
    };

    $self->read_history($term);

    require Time::HiRes;
    require Text::ParseWords;
    while ( defined( $_ = $term->readline(prompt) ) ) {
        select stdout();

        @ARGV = Text::ParseWords::shellwords($_);
        my $cmd = $ARGV[0];
        next unless defined $cmd && length $cmd;

        last if $cmd =~ /^(q|quit|exit)$/i;

        if ( $cmd =~ s/^!// ) {
            shift @ARGV;
            system( $cmd, @ARGV );
        }
        elsif ( $cmd eq 'which' ) {
            puts root_name();
        }
        elsif ( $cmd eq 'use' ) {
            my $name = $ARGV[1];
            if ($name) {
                if ( $name eq 'global' ) {
                    $Beagle::Util::ROOT = '';
                }
                else {
                    if ( roots()->{$name} ) {
                        set_current_root_by_name($name);
                    }
                    else {
                        warn "invalid beagle name: $name";
                        next;
                    }
                }
            }
        }
        elsif ( $cmd eq 'switch' ) {
            my $name = $ARGV[1];
            if ($name) {
                if ( $name eq 'global' ) {
                    $Beagle::Util::ROOT = '';
                    $name                      = '';
                }
                else {
                    if ( roots()->{$name} ) {
                        set_current_root_by_name($name);
                    }
                    else {
                        warn "invalid beagle name: $name";
                        next;
                    }
                }
                write_file(
                    File::Spec->catfile( kennel, 'init' ),
                    "# DO NOT EDIT THIS FILE\nexport BEAGLE_NAME=$name\n"
                );
            }
        }
        else {
            local $Beagle::Util::ROOT = $Beagle::Util::ROOT;
            if (   $self->spawn
                || $ARGV[0] eq 'web'
                || grep { $_ eq '--page' || $_ eq '--spawn' } @ARGV )
            {
                local $ENV{BEAGLE_ROOT} = $Beagle::Util::ROOT;
                my $start = Time::HiRes::time();
                system( $0, grep { $_ ne '--spawn' } @ARGV );
                show_time($start) if enabled_devel;

            }
            else {

                # backup settings
                my ( $devel, $cache, $root ) =
                  ( enabled_devel(), enabled_cache(), current_root('not die') );

                my $start = Time::HiRes::time();
                eval { Beagle::Cmd->run };
                print $@, newline() if $@;
                show_time($start) if enabled_devel;

                # restore settings
                $devel ? enable_devel() : disable_devel();
                $cache ? enable_cache() : disable_cache();
                set_current_root($root) if $root;
            }
        }
        $self->write_history($term);
    }
}

sub show_time {
    my $start = shift;
    warn newline(), sprintf( '%.6f', Time::HiRes::time() - $start ), ' seconds';
}

sub history_file {
    return catfile( kennel(), '.history' );
}

sub read_history {
    my $self = shift;
    my $term = shift;
    return unless -f history_file();
    if ( $term->can('ReadHistory') ) {
        $term->ReadHistory(history_file) or die $!;
    }
}

sub write_history {
    my $self = shift;
    my $term = shift;

    if ( $term->can('GetHistory') ) {
        my @h = $term->GetHistory;
        my $size = core_config->{history_size} || 100;
        splice @h, 0, @h - $size if @h > $size;
        write_file( history_file, join "\n", @h, '' );
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::shell - interactive shell

=head1 SYNOPSIS

    $ beagle shell

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011-2012 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

