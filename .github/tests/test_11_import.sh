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

# TODO: Edit here down
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

teardown_suite() {
  rm -f -d "striptracks.txt" "striptracks_env.txt" "$video1_dir/${test_video1%.webm}.mkv" "$video1_dir/${test_video1%.webm}.json" "$video1_dir/$test_video1" "$video1_dir" "/tmp/$test_video1" "$test_video1"
  unset radarr_eventtype striptracks_arr_config
}
