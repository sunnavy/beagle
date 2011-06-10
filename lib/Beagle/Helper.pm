package Beagle::Helper;

use warnings;
use strict;
use File::Spec::Functions qw/catdir splitdir rel2abs catfile splitpath/;
use Encode;
use Encode::Locale;
use Carp;
use File::Slurp;
use Date::Format;
use base 'Exporter';
use List::MoreUtils 'uniq';
use Storable 'dclone', 'nstore', 'retrieve';
use File::Path 'make_path', 'remove_tree';
use HTML::Entities;

our ( $NEWLINE, $IS_WINDOWS, $OUTSIDE_ENCODING, );

BEGIN {
    $IS_WINDOWS = $^O eq "MSWin32" ? 1 : 0;
    $NEWLINE = $IS_WINDOWS ? "\r\n" : "\n";
}

our @EXPORT = qw/
  catfile catdir rel2abs splitpath splitdir read_file write_file append_file
  uniq dclone nstore retrieve format_number format_bytes stdout stderr
  newline is_windows puts  
  user_home file_size parent_dir to_array from_array edit_text max_length
  term_size term_width term_height  mime_type make_path remove_tree
  pretty_datetime parse_datetime confess encode decode 
  encode_entities decode_entities
  /;

require IO::Handle;
my $stdout = IO::Handle->new;
$stdout->fdopen( 1, 'w' );
sub stdout { return $stdout }

my $stderr = IO::Handle->new;
$stderr->fdopen( 2, 'w' );
sub stderr { return $stderr }

use Number::Format;
my $format = Number::Format->new;

sub format_number {
    my $number = $_[-1];
    return $format->format_number($number);
}

sub format_bytes {
    my $size = $_[-1];
    return $format->format_bytes( $size, precision => 1 );
}

sub newline          { $NEWLINE }
sub is_windows       { $IS_WINDOWS }

sub puts {
    if (@_) {
        print(
            encode(
                locale =>,
                join '',
                @_,
                (
                    $_[-1] =~ /$NEWLINE$/
                    ? ()
                    : $NEWLINE
                )
            )
        );
    }
    else {
        print $NEWLINE;
    }
}

sub term_size {
    my ( $width, $height );

    if (is_windows) {
        require Term::Size::Win32;
        ( $width, $height ) = Term::Size::Win32::chars(*STDOUT);
    }
    else {
        require Term::Size;
        ( $width, $height ) = Term::Size::chars(*STDOUT);
    }

    $width  ||= 80;
    $height ||= 24;
    return $width, $height;
}

sub term_width {
    return ( ( term_size() )[0] );
}

sub term_height {
    return ( ( term_size() )[1] );
}

=head2 parent_dir

return the dir's parent dir, the arg must be a dir path

=cut

sub parent_dir {
    my $dir  = $_[-1];
    my @dirs = splitdir($dir);
    pop @dirs;
    return catdir(@dirs);
}

sub file_size {
    my $file = $_[-1];
    return 0 unless -e $file;
    my $size = -s $file;
    return format_bytes($size);
}

sub user_home {
    require File::HomeDir;
    return File::HomeDir->my_home;
}

sub parse_datetime {
    require DateTimeX::Easy;
    my $dt = DateTimeX::Easy->new(@_);
    return $dt ? $dt->epoch : ();
}

sub pretty_datetime {
    my $date = shift;
    return '' unless defined $date;
    require DateTime;
    my $diff =
      DateTime->from_epoch( epoch => time ) -
      DateTime->from_epoch( epoch => $date );

    if ( $diff->is_negative < 0 ) {
        return 'in the future';
    }
    else {
        for my $unit (qw/year month week day hour minute/) {
            if ( my $v = $diff->in_units( $unit . 's' ) ) {
                if ( $v == 1 ) {
                    if ( $unit eq 'day' ) {
                        return "yesterday";
                    }
                    else {
                        return "$v $unit ago";
                    }
                }
                else {
                    return "$v ${unit}s ago";
                }
            }
        }
        return "just now";
    }
}

sub max_length {
    my @list   = @_;
    my $length = 0;
    for (@list) {
        next unless defined;
        $length = length if $length < length;
    }

    return $length;
}

sub to_array {
    my $str = $_[-1];
    return [] unless defined $str;
    return [ split /\s*,\s*/, $str ];
}

sub from_array {
    my $tags = $_[-1];
    return '' unless $tags && ref $tags eq 'ARRAY';
    return join ', ', @$tags;
}

sub edit_text {
    my $text = $_[-1];

    require Proc::InvokeEditor;
    return scalar Proc::InvokeEditor->edit($text);
}

use MIME::Types;
my $mime_types = MIME::Types->new;

sub mime_type {
    my $file = shift;
    my $type;
    if ( $file && $file =~ /.*\.(\S+)\s*$/i ) {
        $type = $mime_types->mimeTypeOf($1);
    }
    return $type ? "$type" : 'application/octet-stream';
}

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

