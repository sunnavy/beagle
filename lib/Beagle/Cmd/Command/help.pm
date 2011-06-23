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

    my $desc = $cmd->description;
    $desc = "\n$desc" if length $desc;

    $cmd->usage->{options} = [
        sort { $a->{desc} cmp $b->{desc} }
        grep { $_->{name} ne 'help' } @{ $cmd->usage->{options} }
    ];
    puts join newline(), $cmd->usage->leader_text, $desc,
      $cmd->usage->option_text;
}

sub usage_desc { "show beagle help" }

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

