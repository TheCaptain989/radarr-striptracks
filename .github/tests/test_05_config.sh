#!/bin/bash

# bash_unit tests
# Configuration file

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  export radarr_eventtype="Import"
  initialize_variables
  export striptracks_arr_config="config.xml"
  cat >$striptracks_arr_config <<EOF
<Config>
  <BindAddress>*</BindAddress>
  <Port>7878</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>True</LaunchBrowser>
  <ApiKey>0123456789ABCDEF</ApiKey>
  <AuthenticationMethod>Forms</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Branch>master</Branch>
  <LogLevel>info</LogLevel>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <UrlBase></UrlBase>
  <InstanceName>Radarr</InstanceName>
  <UpdateMechanism>Docker</UpdateMechanism>
</Config>  
EOF
  initialize_mode_variables
  fake log :
}

test_api_url() {
  fake get_version :
  fake check_compat :
  check_config
  assert_equals "http://localhost:7878/api/v3" "$striptracks_api_url"
}

test_api_curl_failure() {
  assert_status_code 17 "check_config 2>/dev/null"
}

test_api_bad_version() {
  fake get_version :
  fake check_compat return 1
  assert_status_code 8 "check_config 2>/dev/null"
}

teardown_suite() {
  rm -f "$striptracks_arr_config"
  unset radarr_eventtype striptracks_arr_config
}
