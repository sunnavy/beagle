use Test::More;
use Beagle::Helper;

my @subs = qw/
  catfile catdir rel2abs splitdir read_file write_file append_file uniq
  dclone nstore retrieve
  format_number format_bytes stdout stderr
  newline is_windows  mime_type
  puts  user_home file_size parent_dir
  to_array from_array edit_text max_length
  term_size term_width term_height make_path remove_tree
  pretty_datetime parse_datetime confess encode decode/;

for (@subs) {
    can_ok( main, $_ );
}

done_testing();
