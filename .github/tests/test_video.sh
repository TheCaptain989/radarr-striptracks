#!/bin/bash

# bash_unit tests
# Configuration file

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  export striptracks_video="test_video.mp4"
  fake log :
}

test_video_var_not_set() {
  unset striptracks_video
  assert_status_code 1 "check_video 2>/dev/null"
}

test_video_not_exist() {
  rm -f "$striptracks_video"
  assert_status_code 5 "check_video 2>/dev/null"
}

test_set_temp_video() {
  touch "$striptracks_video"
  check_video
  assert_matches "^\./test_\.tmp\..{6}$" "$striptracks_tempvideo"
}

teardown_suite() {
  rm -f "$striptracks_video"
}
