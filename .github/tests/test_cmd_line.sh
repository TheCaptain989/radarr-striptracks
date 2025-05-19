#!/bin/bash

# bash_unit test

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
}

test_cmd_options_require_argument() {
  assert_status_code 1 "process_command_line --log" && \
  assert_status_code 1 "process_command_line --file" && \
  assert_status_code 1 "process_command_line --audio" && \
  assert_status_code 1 "process_command_line --subtitles" && \
  assert_status_code 1 "process_command_line --config" &&
}

test_cmd_unknown_option(){
  assert_status_code 20 "process_command_line --will-fail"
}

test_cmd_invalid_audio_option(){
  assert_status_code 2 "process_command_line --audio eng"
}

test_cmd_invalid_subs_option(){
  assert_status_code 3 "process_command_line --subtitles eng"
}

test_cmd_dup_options_combo_1(){
  assert_equals "Warning|Both positional and named arguments set for audio. Using :org" "process_command_line :eng -a :org 2>&1"
}

test_cmd_dup_options_combo_2(){
  assert_equals "Warning|Both positional and named arguments set for subtitles. Using :org" "process_command_line :eng -s :org 2>&1"
}
