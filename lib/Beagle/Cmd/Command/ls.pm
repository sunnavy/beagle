package Beagle::Cmd::Command::ls;
use Encode;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

has type => (
    isa           => "Str",
    is            => "rw",
    documentation => "type",
    cmd_aliases   => 't',
    traits        => ['Getopt'],
);

has 'created-before' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'created_before',
    documentation => "show entries created before the time",
    traits        => ['Getopt'],
);

has 'created-after' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'created_after',
    documentation => "show entries created after the time",
    traits        => ['Getopt'],
);

has 'updated-before' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'updated_before',
    documentation => "show entries updated before the time",
    traits        => ['Getopt'],
);

has 'updated-after' => (
    isa           => "Str",
    is            => "rw",
    accessor      => 'updated_after',
    documentation => "show entries updated after the time",
    traits        => ['Getopt'],
);

has 'all' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "show all the beagles",
    cmd_aliases   => 'a',
    traits        => ['Getopt'],
);

has 'limit' => (
    isa           => 'Num',
    is            => 'rw',
    documentation => "limit number of entries",
    cmd_aliases   => 'l',
    traits        => ['Getopt'],
);

has 'draft' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "only show draft entries",
    traits        => ['Getopt'],
);

has 'final' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => "only show not-draft entries",
    traits        => ['Getopt'],
);

has 'order' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'updated',
    documentation =>
      "order of entries for each beagle, should be one of name|updated|created",
    traits => ['Getopt'],
);

has 'marks' => (
    isa         => 'Str',
    is          => 'rw',
    cmd_aliases => 'm',
    documentation =>
      "show show entries that has these masks seperated by comma",
    traits => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub command_names { qw/ls list/ };

sub filter {
    my $self = shift;
    my ( $bh, $opt, $args ) = @_;

    my @found;

    my $type = $self->type;

    my %condition;
    %condition = %{ $opt->{condition} } if $opt->{condition};

    for my $attr (keys %{$bh->entry_info}) {
        if (   $type eq $bh->entry_info->{$attr}{type}
            || $type eq 'all' )
        {
            for my $entry ( @{ $bh->$attr } ) {
                next
                  if ( $self->draft && !$entry->draft )
                  || ( $self->final && $entry->draft );

                next unless is_in_range( $entry, %condition );
                push @found, $entry;
            }
        }

    }

    if (@$args) {
        my @results;
        for my $entry (@found) {
            my $pass    = 1;
            my $content = $entry->serialize( id => 1 );
            for my $regex (@$args) {
                undef $pass unless $content =~ qr/$regex/mi;
            }
            push @results, $entry if $pass;
        }
        @found = @results;
    }

    if ( $self->marks ) {
        my @marks       = split /\s*,\s*/, $self->marks;
        my $marks       = entry_marks();

        my $filter_mark = sub {
            my $id    = shift;
            return 1 unless @marks;
            return unless $marks->{$id};
            for my $mark (@marks) {
                if ( !exists $marks->{$id}{$mark} ) {
                    return;
                }
            }
            return 1;
        };

        @found = grep { $filter_mark->( $_->id ) } @found;
    }

    return @found;
}

sub _prepare {
    my $self = shift;
    my $type = $self->type || 'all';
    $self->type($type);

    my $root = beagle_root('not die');
    require Beagle::Handler;

    if ( !$self->all && $root ) {
        return Beagle::Handler->new( root => $root );
    }
    else {
        my $all = beagle_roots();
        $self->all(1);
        return map { Beagle::Handler->new( root => $all->{$_}{local} ) }
          keys %$all;
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my @bh = $self->_prepare();

    my %condition = map { $_ => $self->$_ }
      qw/created_before created_after updated_before updated_after/;

    for my $item ( keys %condition ) {
        next unless defined $condition{$item};
        my $epoch = parse_datetime( $condition{$item} )
          or die "failed to parse datetime from string $condition{$item}";

        $condition{$item} = $epoch;
    }

    $opt->{condition} = \%condition;

    my @found;
    for my $bh ( sort { $a->name cmp $b->name } @bh ) {
        push @found, $self->filter( $bh, $opt, $args );
        if (   $self->limit
            && $self->limit > 0
            && $self->order =~ /name/i
            && @found >= $self->limit )
        {
            @found = @found[ 0 .. $self->limit - 1 ];
            last;
        }
    }

    if (@found) {
        $self->show_result(@found);
    }
}

sub show_result {
    my $self  = shift;
    my @found = @_;
    return unless @found;

    my $limit = $self->limit;
    $limit = 0 if !$limit || $limit < 0;

    my $order = lc $self->order;
    if ( $order ne 'name' ) {
        if ( $order eq 'type' ) {
            if ( $limit && $limit < @found ) {
                @found =
                  ( sort { $a->$order cmp $b->$order } @found )
                  [ 0 .. $limit - 1 ];
            }
            else {
                @found =
                  sort { $a->$order cmp $b->$order } @found;
            }
        }
        elsif ( $found[0]->can($order) ) {
            if ( $limit && $limit < @found ) {
                @found =
                  ( sort { $b->$order <=> $a->$order } @found )
                  [ 0 .. $limit - 1 ];
            }
            else {
                @found = sort { $b->$order <=> $a->$order } @found;
            }
        }
        else {
            die "invalid order: $order";
        }
    }

    @found = @found[ 0 .. $self->limit - 1 ]
      if $self->limit && $self->limit > 0 && $self->limit < @found;

    return unless @found;

    my $all = beagle_roots();

    require Text::Table;
    my $tb;
    if ( $self->verbose ) {
        $tb = Text::Table->new( 'name', 'type', 'id', 'created', 'updated',
            'summary' );
        $tb->load(
            map {
                [
                    root_name( $_->root ),
                    $_->type,
                    $_->id,
                    pretty_datetime( $_->created ),
                    pretty_datetime( $_->updated ),
                    $_->summary(10),
                ]
              } @found
        );
    }
    else {
        $tb = Text::Table->new();
        $tb->load( map { [ $_->id, $_->summary(20) ] } @found );
    }
    puts $tb;
}

sub usage_desc { "ls entries" }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::ls - list/search entries

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

