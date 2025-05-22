#!/bin/bash

# bash_unit tests
# Command line options

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
}

test_cmd_options_require_argument() {
  assert_status_code 1 "process_command_line --log" && \
  assert_status_code 1 "process_command_line --file" && \
  assert_status_code 1 "process_command_line --config"
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

teardown() {
  unset STRIPTRACKS_ARGS striptracks_prelogmessage
}