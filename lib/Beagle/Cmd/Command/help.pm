package Beagle::Cmd::Command::help;
use Encode;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::GlobalCommand App::Cmd::Command::help/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    App::Cmd::Command::help::execute(@_);
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

