#!/bin/bash

# bash_unit tests
# Required binaries
# mkvtoolnix installed from BuildImage.yml

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  fake log :
}

test_binaries_present() {
  assert check_required_binaries
}
test_missing_mkvmerge() {
  sudo mv /usr/bin/mkvmerge /usr/bin/mkvmerge.bak
  assert_status_code 4 "check_required_binaries 2>/dev/null" && \
  assert_matches "^Error\|/usr/bin/mkvmerge is required" "$(check_required_binaries 2>&1)"
  sudo mv /usr/bin/mkvmerge.bak /usr/bin/mkvmerge
}

test_missing_mkvpropedit() {
  sudo mv /usr/bin/mkvpropedit /usr/bin/mkvpropedit.bak
  assert_status_code 4 "check_required_binaries 2>/dev/null" && \
  assert_matches "^Error\|/usr/bin/mkvpropedit is required" "$(check_required_binaries 2>&1)"
  sudo mv /usr/bin/mkvpropedit.bak /usr/bin/mkvpropedit
}
