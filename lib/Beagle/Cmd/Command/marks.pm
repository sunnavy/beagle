package Beagle::Cmd::Command::marks;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $marks = entry_marks;

    my $subcmd;
    if ( @$args && $args->[0] =~ /^(?:export|import)$/ ) {
        $subcmd = shift @$args;
    }

    if ($subcmd) {
        require JSON;
        if ( $subcmd eq 'export' ) {
            my $path = shift @$args;
            my $converted = {};
            for my $id ( keys %$marks ) {
                if ( $marks->{$id} && %{ $marks->{$id} } ) {
                    $converted->{$id} = [ sort keys %{ $marks->{$id} } ];
                }
            }

            if ( $path && $path ne '-' ) {
                my $out = JSON::to_json( $converted, { utf8 => 1, pretty => 1 } );
                write_file( $path, $out );
                puts 'exported.';
            }
            else {
                my $out = JSON::to_json( $converted, { pretty => 1 } );
                puts $out;
            }
        }
        elsif ( $subcmd eq 'import' ) {
            my $path = shift @$args;
            my $in;
            if ( $path && $path ne '-' ) {
                $in = decode( 'utf8', read_file( $path ) );
            }
            else {
                local $/;
                $in = decode( locale => <STDIN> );
            }
            my $converted = JSON::from_json( $in );
            for my $id ( keys %$converted ) {
                next unless $converted->{$id} && @{ $converted->{$id} };
                $marks->{$id} = { map { $_ => 1 } @{ $converted->{$id} } };
            }
            set_entry_marks($marks);
            puts 'imported.';
        }
    }
    else {

        my @ids;
        if (@$args) {
            for my $i (@$args) {
                my @ret = resolve_entry( $i, handler => handler() || undef );
                unless (@ret) {
                    @ret = resolve_entry($i) or die_entry_not_found($i);
                }
                die_entry_ambiguous( $i, @ret ) unless @ret == 1;
                my $id = $ret[0]->{id};
                puts @ids, $id;
            }
        }
        else {
            @ids = keys %$marks;
        }

        @ids = grep { %{ $marks->{$_} } } @ids;

        if (@ids) {
            require Text::Table;
            my $tb = Text::Table->new();
            $tb->load( map { [ $_, join ', ', sort keys %{ $marks->{$_} } ] }
                  @ids );
            puts $tb;
        }
    }
}

sub usage_desc { 'show/export/import entry marks' }

1;

__END__

=head1 NAME

Beagle::Cmd::Command::marks - show/export/import entry marks

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

