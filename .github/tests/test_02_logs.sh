#!/bin/bash

# bash_unit tests
# Logs

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
}

test_create_log() {
  check_log >/dev/null
  assert_equals "/config/logs/striptracks.txt" "$striptracks_log" && \
  assert "test -f $striptracks_log"
}

todo_log_not_writable() {
  # Doesn't work properly in a container
  local striptracks_log="./striptracks.txt"
  touch "$striptracks_log"
  chmod -f a-w "$striptracks_log"
  check_log 2>/dev/null
  assert_equals 12 $striptracks_exitstatus
}

teardown() {
  rm -f "./striptracks.txt"
  unset striptracks_log striptracks_exitstatus
}
