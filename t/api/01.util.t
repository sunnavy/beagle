use Test::More;
use Beagle::Util;

my @subs = qw/
  enabled_devel enable_devel disable_devel enabled_cache enable_cache disable_cache
  set_beagle_root beagle_root beagle_name set_beagle_name check_beagle_root
  beagle_static_root beagle_home core_config user_alias
  set_core_config set_user_alias  beagle_roots set_beagle_roots entry_map
  set_entry_map default_format split_id root_name name_root root_type
  system_alias create_beagle alias aliases resolve_id die_entry_not_found
  die_entry_ambiguous handle handles beagle_share_root resolve_entry
  is_in_range parse_wiki  parse_markdown entry_marks set_entry_marks
  whitelist set_whitelist detect_beagle_roots
  detect_beagle_roots beagle_home_roots beagle_home_cache
  cache_name beagle_share_root entry_marks set_entry_marks
  beagle_spread_template_roots beagle_web_template_roots
  entry_type_info entry_types
  entry_map_path entry_marks_path
  /;

for (@subs) {
    can_ok( main, $_ );
}

done_testing();
