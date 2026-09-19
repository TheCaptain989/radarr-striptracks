#!/bin/bash

# bash_unit tests
# Radarr API
# Radarr installed from BuildImage.yml

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY" >>striptracks.txt; done; )}

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  fake log :
  export test_video1="Racism_is_evil.webm"
  export video1_dir="Carmencita (1894)"
  [ -d "$video1_dir" ] || mkdir "$video1_dir"
  [ -f "/tmp/$test_video1" ] || { wget -q "https://upload.wikimedia.org/wikipedia/commons/transcoded/e/e4/%27Racism_is_evil%2C%27_Trump_says.webm/%27Racism_is_evil%2C%27_Trump_says.webm.240p.vp9.webm?download" -O "/tmp/$test_video1"; }
  [ -f "$test_video1" ] || cp "/tmp/$test_video1" .
  printenv | grep -E '^(radarr_|striptracks_)' | sort >striptracks_env.txt
}

setup() {
  export radarr_transfermode="Move"
  initialize_variables
  # initialize_mode_variables
  check_log >/dev/null
  check_required_binaries
  check_config_file
}

add_video() {
  call_api 0 "Adding video to Radarr." "POST" "movie" "{\"QualityProfileId\":1, \"TmdbId\":16612, \"Title\":\"Carmencita\", \"path\":\"$PWD/$video1_dir\", \"monitored\":true, \"rootFolderPath\":\"$PWD/\", \"movieFile\":{}}"
}

configure_import() {
  call_api 0 "Setting ${striptracks_type^} configuration." "GET" "config/mediamanagement/1"
  radarr_config="$(echo $striptracks_result | jq -crM ".useScriptImport=true | .scriptImportPath=\"$(realpath ../../root/usr/local/bin/striptracks.sh)\"")"
  call_api 0 "Setting ${striptracks_type^} configuration." "PUT" "config/mediamanagement/1" "$radarr_config"
}

get_video_info() {
  call_api 0 "Getting video info from Radarr." "GET" "movie/$radarr_movie_id"
}

test_radarr_z01_add_video() {
  add_video
  radarr_movie_id=$(echo "$striptracks_result" | jq -crM '.id?')
  initialize_mode_variables
  get_video_info
  echo $striptracks_result | jq -r >"$video1_dir/${test_video1%.webm}.json"
  assert_equals "Carmencita" "$(echo $striptracks_result | jq -crM '.title')"
}

test_radarr_z02_configure_import() {
  configure_import
  assert_equals 0 ${striptracks_exitstatus:-0}
}

# Metadata null filtering (see issue #128)
# Fakes call_api and captures the JSON payload it would have sent to the bulk endpoint.
# The payload is written to a file because bash_unit isolates each test.
setup_metadata_test() {
  # Mirrors the Radarr values set by initialize_mode_variables()
  export striptracks_metadata_via_api=("releaseGroup" "indexerFlags" "sceneName" "edition")
  export striptracks_videofile_api="moviefile"
  export striptracks_videofile_id=42
  # shellcheck disable=SC2016
  fake call_api 'echo "${!#}" >metadata_payload.json; striptracks_result="[{\"id\":42}]"'
}

metadata_payload_keys() {
  jq -crM '.[0] | keys_unsorted | join(",")' metadata_payload.json
}

test_set_metadata_omits_null_fields() {
  setup_metadata_test
  export striptracks_original_metadata='{"quality":{"quality":{"name":"Bluray-1080p"}},"releaseGroup":"RARBG","indexerFlags":1,"sceneName":null,"edition":null}'
  set_metadata
  assert_equals "id,quality,releaseGroup,indexerFlags" "$(metadata_payload_keys)"
  assert_equals "RARBG" "$(jq -crM '.[0].releaseGroup' metadata_payload.json)"
}

test_set_metadata_omits_absent_fields() {
  # After the capture in detect_languages() drops nulls, the fields are missing rather than null
  setup_metadata_test
  export striptracks_original_metadata='{"quality":{"quality":{"name":"WEBDL-720p"}},"releaseGroup":"NTb"}'
  set_metadata
  assert_equals "id,quality,releaseGroup" "$(metadata_payload_keys)"
}

test_set_metadata_keeps_zero_indexerflags() {
  # A zero value is not null and must still be sent
  setup_metadata_test
  export striptracks_original_metadata='{"quality":{"quality":{"name":"Bluray-1080p"}},"releaseGroup":"RARBG","indexerFlags":0,"sceneName":null,"edition":null}'
  set_metadata
  assert_equals "id,quality,releaseGroup,indexerFlags" "$(metadata_payload_keys)"
  assert_equals "0" "$(jq -crM '.[0].indexerFlags' metadata_payload.json)"
}

test_set_metadata_keeps_empty_string_fields() {
  # An empty string is not null and must still be sent
  setup_metadata_test
  export striptracks_original_metadata='{"quality":{"quality":{"name":"Bluray-1080p"}},"releaseGroup":"","indexerFlags":null,"sceneName":null,"edition":null}'
  set_metadata
  assert_equals "id,quality,releaseGroup" "$(metadata_payload_keys)"
  assert_equals "" "$(jq -crM '.[0].releaseGroup' metadata_payload.json)"
}

test_set_metadata_always_sends_id() {
  # Every optional field null still leaves a well formed payload carrying the id
  setup_metadata_test
  export striptracks_original_metadata='{"quality":{"quality":{"name":"SDTV"}},"releaseGroup":null,"indexerFlags":null,"sceneName":null,"edition":null}'
  set_metadata
  assert_equals "id,quality" "$(metadata_payload_keys)"
  assert_equals "42" "$(jq -crM '.[0].id' metadata_payload.json)"
}

todo_radarr_z03_video_convert() {
  # Read in values from first test
  striptracks_result="$(cat "$video1_dir/${test_video1%.webm}.json")"
  radarr_moviefile_path="$(echo $striptracks_result | jq -crM '.movieFile.path')"
  radarr_moviefile_id="$(echo $striptracks_result | jq -crM '.movieFile.id')"
  radarr_movie_id="$(echo $striptracks_result | jq -crM '.id')"
  radarr_movie_path="$(echo $striptracks_result | jq -crM '.path')"
  radarr_movie_title="$(echo $striptracks_result | jq -crM '.title')"
  radarr_movie_year="$(echo $striptracks_result | jq -crM '.year')"
  assert_status_code 0 "delete_video"
}

teardown_suite() {
  rm -f -d "striptracks.txt" "striptracks_env.txt" "metadata_payload.json" "$video1_dir/${test_video1%.webm}.mkv" "$video1_dir/${test_video1%.webm}.json" "$video1_dir/$test_video1" "$video1_dir" "/tmp/$test_video1" "$test_video1"
  unset radarr_eventtype striptracks_arr_config
}
