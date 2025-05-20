#!/bin/bash

# bash_unit tests
# Required binaries

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  fake log :
}

test_missing_mkvmerge() {
  assert_status_code 4 "check_required_binaries 2>/dev/null" && \
  assert_matches "^Error\|/usr/bin/mkvmerge is required" "$(check_required_binaries 2>&1)"
}

test_missing_mkvpropedit() {
  sudo touch /usr/bin/mkvmerge
  assert_status_code 4 "check_required_binaries 2>/dev/null" && \
  assert_matches "^Error\|/usr/bin/mkvpropedit is required" "$(check_required_binaries 2>&1)"
}

test_binaries_present() {
  sudo touch /usr/bin/mkvmerge /usr/bin/mkvpropedit
  assert check_required_binaries
}

teardown() {
  sudo rm -f "/usr/bin/mkvmerge" "/usr/bin/mkvpropedit"
}
