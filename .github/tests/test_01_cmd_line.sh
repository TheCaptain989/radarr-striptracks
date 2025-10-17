#!/bin/bash

# bash_unit tests
# Basic command line options

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
}

test_cmd_options_require_argument() {
  assert_status_code 1 "process_command_line --log" && \
  assert_status_code 1 "process_command_line --file" && \
  assert_status_code 1 "process_command_line --config" && \
  assert_status_code 1 "process_command_line --skip-profile"
}

test_cmd_unknown_option() {
  assert_status_code 20 "process_command_line --will-fail 2>&1"
}

test_cmd_invalid_audio_option() {
  assert_status_code 2 "process_command_line --audio eng 2>&1"
}

test_cmd_invalid_subs_option() {
  assert_status_code 3 "process_command_line --subtitles eng 2>&1"
}

test_cmd_invalid_priority_option() {
  assert_matches "^Error\|.*low, medium, or high" "$(process_command_line --priority 1 2>&1)"
}

test_cmd_dup_options_audio() {
  assert_matches "^Warning\|Both positional.*audio" "$(process_command_line :eng -a :org 2>&1)"
}

test_cmd_dup_options_subs() {
  assert_matches "^Warning\|Both positional.*subtitles" "$(process_command_line :fre :eng -s :org 2>&1)"
}

test_env_usage_with_cmd() {
  local STRIPTRACKS_ARGS="-a :org"
  process_command_line -a :eng
  assert_matches "^Warning\|STRIPTRACKS_ARGS environment.*" "$striptracks_prelogmessage"
}

test_env_usage() {
  local STRIPTRACKS_ARGS="-a :org"
  process_command_line
  assert_equals "Info|Using settings from environment variable." "$striptracks_prelogmessage"
}

test_set_reorder(){
  process_command_line --reorder
  assert_equals "true" "$striptracks_reorder"
}

test_set_disable_recycle(){
  process_command_line --disable-recycle
  assert_equals "false" "$striptracks_recycle"
}

test_multiple_skips() {
  process_command_line --skip-profile 123 --skip-profile 456
  local IFS=,
  assert_equals "123,456" "${striptracks_skip_profile[*]}"
}

teardown() {
  unset STRIPTRACKS_ARGS striptracks_prelogmessage
}