package Beagle::Cmd::Command::help;
use Encode;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::GlobalCommand App::Cmd::Command::help/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opts, $args ) = @_;

    ( my $cmd, $opts, $args ) = $self->app->prepare_command(@$args);

    require Pod::Usage;
    require Pod::Find;

    my $out;
    open my $fh, '>', \$out or die $!;
    Pod::Usage::pod2usage(
        -verbose   => 2,
        -input     => Pod::Find::pod_where(
            { -inc => 1 },
            ref $cmd
        ),
        -output => $fh,
        -exitval => 'NOEXIT',
    );
    close $fh;

    $cmd->usage->{options} = [
        sort { $a->{desc} cmp $b->{desc} }
        grep { $_->{name} ne 'help' } @{ $cmd->usage->{options} }
    ];

    # '' is for a newline
    my $opt = join newline(), 'OPTIONS', $cmd->usage->option_text, '';

    unless ( $out =~ s!(?=^AUTHOR)!$opt!m ) {
        $out .= $opt;
    }
    puts $out;
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::help - show beagle help


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

