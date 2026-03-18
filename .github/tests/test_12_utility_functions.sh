#!/bin/bash

# bash_unit tests
# Additional utility function tests

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  fake log :
}

test_setup_ansi_colors() {
  setup_ansi_colors
  assert_not_equals "" "$ansi_red"
  assert_not_equals "" "$ansi_green"
  assert_not_equals "" "$ansi_yellow"
  assert_not_equals "" "$ansi_cyan"
  assert_not_equals "" "$ansi_nc"
}

test_strip_ansi_codes() {
  setup_ansi_colors
  assert_equals "Error|Test message" "$(echo -e "${ansi_red}Error|Test message${ansi_nc}" | strip_ansi_codes)"
}

test_echo_ansi_without_color() {
  export striptracks_noansi="true"
  assert_equals "Error|Test message" "$(echo_ansi "Error|Test message" 2>&1)"
}

test_read_xml() {
  local xml='<root><item>value</item></root>'
  while read_xml; do
    [[ $striptracks_xml_entity = "item" ]] && local item=$striptracks_xml_content
  done <<<"$xml"
  assert_equals "value" "$item"
}

test_escape_string() {
  local input='test "string" with quotes'
  assert_equals 'test \"string\" with quotes' "$(escape_string "$input")"
}

test_check_compat_apiv3() {
  striptracks_arr_version="3.0.0"
  check_compat "apiv3"
  assert_equals 0 $?
}

test_check_compat_languageprofile() {
  striptracks_type="sonarr"
  striptracks_arr_version="3.0.0"
  check_compat "languageprofile"
  assert_equals 0 $?
}

test_resolve_code_conflict() {
  striptracks_audiokeep=":eng:fra"
  striptracks_profileLangCodes=":eng"
  resolve_code_conflict
  assert_equals ":eng:fra" "$striptracks_audiokeep"
}

test_set_title_and_exit_if_nothing_removed() {
  fake end_script 'end_script_called=1'
  fake execute_mkv_command :
  export striptracks_json='{"tracks":[{"id":0,"type":"video"},{"id":1,"type":"audio"},{"id":2,"type":"audio"}]}'
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","striptracks_keep":true},{"id":1,"type":"audio","striptracks_keep":true},{"id":2,"type":"audio","striptracks_keep":true}]}'
  export striptracks_video="./Testing.mkv"
  export striptracks_title="Test Title"
  set_title_and_exit_if_nothing_removed
  # Should call end_script since nothing removed
  assert_equals "1" "$end_script_called"
}

teardown() {
  unset striptracks_arr_version striptracks_type striptracks_json striptracks_json_processed striptracks_video striptracks_title striptracks_exitstatus
}