use Test::More;
use Beagle::Util;

my @subs = qw/
  enabled_devel enable_devel disable_devel enabled_cache enable_cache disable_cache
  set_backend_root backend_root root_name set_backend_root_by_name check_backend_root
  current_static_root kennel core_config user_alias
  set_core_config set_user_alias backend_roots set_backend_roots entry_map
  set_entry_map default_format split_id root_name name_root root_type
  system_alias create_backend alias aliases resolve_id die_entry_not_found
  die_entry_ambiguous handle handles share_root resolve_entry
  is_in_range parse_wiki  parse_markdown entry_marks set_entry_marks
  whitelist set_whitelist detect_roots
  detect_roots backend_roots_root cache_root
  cache_name share_root entry_marks set_entry_marks
  spread_template_roots web_template_roots
  entry_type_info entry_types
  entry_map_path entry_marks_path
  /;

for (@subs) {
    can_ok( main, $_ );
}

done_testing();
