package Beagle::Web::Form;

use Any::Moose;
use Class::Load;

has fields => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] },
);

sub sorted_fields {
    my $self = shift;
    return [ sort { $a->name cmp $b->name } @{ $self->fields } ];
}

sub render {
    my $self = shift;
    my $str  = '';
    for my $field ( $self->sorted_fields ) {
        $str .= $field->render();
    }
    return $str;
}

sub BUILD {
    my $self = shift;
    my $opt  = shift;
    die 'need field_list as arrayref'
      unless $opt->{field_list} && ref $opt->{field_list} eq 'ARRAY';

    my @fields;
    my @list = @{$opt->{field_list}};
    while ( @list ) {
        my $name = shift @list;
        my $opt  = shift @list;
        my $type = lc delete $opt->{type};
        $type ||= 'text';
        my $class = "Beagle::Web::Form::$type";
        Class::Load::load_class($class);
        push @fields, $class->new( name => $name, %$opt );
    }
    $self->fields( \@fields );
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

