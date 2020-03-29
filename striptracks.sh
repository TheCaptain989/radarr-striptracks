#!/bin/bash

# Video remuxing script designed for use with Radarr
# Automatically strips out unwanted audio and subtitle streams, keeping only the desired languages.
#  https://github.com/TheCaptain989/radarr-striptracks

# Adapated and corrected from Endoro's post 1/5/2014:
#  https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889
#
# Put a colon `:` in front of every language code.  Expects ISO639-2 codes

# Dependencies:
#  mkvmerge
#  awk

# Exit codes:
#  0 - success
#  1 - no movie file specified on command line
#  2 - no audio language specified on command line
#  3 - no subtitle language specified on command line
#  5 - specified movie file not found
# 10 - remuxing completed, but no output file found
# 11 - success, but unable to access Radarr API due to missing Movie ID
# 12 - success, but unable to access Radarr API due to missing config file

RADARR_CONFIG=/config/config.xml
LOG=/config/logs/striptracks.txt
MAXLOGSIZE=1024000
MAXLOG=4
MOVIE="$radarr_moviefile_path"
TEMPMOVIE="$MOVIE.tmp"
NEWMOVIE="${MOVIE%.*}.mkv"

function usage {
  usage="
Striptracks.sh
Video remuxing script designed for use with Radarr

Source: https://github.com/TheCaptain989/radarr-striptracks

Usage:
  $0 [-d] <audio_languages> <subtitle_languages>

Arguments:
  audio_languages       # ISO639-2 code(s) prefixed with a colon \`:\`
                          Multiple codes may be concatenated.
  subtitle_languages    # ISO639-2 code(s) prefixed with a colon \`:\`
                          Multiple codes may be concatenated.

Options:
  -d    # enable debug logging

Examples:
  striptracks.sh :eng:und :eng              # keep English and Undetermined audio and
                                              English subtitles
  striptracks.sh :eng \"\"                    # keep English audio and no subtitles
  striptracks.sh -d :eng:kor:jpn :eng:spa   # Enable debugging, keeping English, Korean,
                                              and Japanese audio, and English and
                                              Spanish subtitles
"
  echo "$usage"
}

# Can still go over MAXLOG if read line is too long
#  Must include whole function in subshell for read to work!
function log {(
  while read
  do
    echo $(date +"%Y-%-m-%-d %H:%M:%S.%1N")\|"$REPLY" >>"$LOG"
    FILESIZE=`wc -c "$LOG" | cut -d' ' -f1`
    if [ $FILESIZE -gt $MAXLOGSIZE ]
    then
      for i in `seq $((MAXLOG-1)) -1 0`
      do
        [ -f "${LOG::-4}.$i.txt" ] && mv "${LOG::-4}."{$i,$((i+1))}".txt"
      done
        [ -f "${LOG::-4}.txt" ] && mv "${LOG::-4}.txt" "${LOG::-4}.0.txt"
      touch "$LOG"
    fi
  done
)}

# Process options
while getopts ":d" opt; do
  case ${opt} in
    d ) # For debug purposes only
      MSG="Debug|Enabling debug logging."
      echo "$MSG" | log
      echo "$MSG"
      DEBUG=1
      printenv | sort | log
    ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$MOVIE" ]; then
  MSG="Error|No movie file specified! Not called from Radarr?"
  echo "$MSG" | log
  echo "$MSG"
  usage 
  exit 1
fi

if [ ! -f "$MOVIE" ]; then
  MSG="Error|Input file not found: \"$MOVIE\""
  echo "$MSG" | log
  echo "$MSG"
  exit 5
fi

if [ -z "$1" ]; then
  MSG="Error|No audio languages specified!"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 2
fi

if [ -z "$2" ]; then
  MSG="Error|No subtitles languages specified!"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 3
fi

MSG="Info|StripTracks|Radarr event: $radarr_eventtype, Movie: $MOVIE, AudioKeep: $1, SubsKeep: $2"
echo "$MSG" | log
echo "$MSG"
echo "" | awk '
BEGIN {
  MKVMerge="/usr/bin/mkvmerge"
  FS="[\t\n: ]"
  IGNORECASE=1
  Debug='$DEBUG'
  OrgVideo='"$MOVIE"'
  TempVideo='"$TEMPMOVIE"'
  MKVVideo='"$NEWMOVIE"'
  AudioKeep='"$1"'
  SubsKeep='"$2"'
  Title=substr(MKVVideo, 1, length(MKVVideo)-4)
  sub(".*/", "", Title)
  if (match(Title,/[a-zA-Z0-9]- /)) {
    Arr[1]=substr(Title,1,RSTART)
    Arr[2]=substr(Title,RSTART+RLENGTH-1)
    Title=Arr[1]":"Arr[2]
  }  # mawk does not have gensub function

  if (Debug) print "Debug|Renaming: \""OrgVideo"\" to \""TempVideo"\""
  Result=system("mv \""OrgVideo"\" \""TempVideo"\"")
  if (Result) {
    print "Error|"Result" renaming \""OrgVideo"\""
    exit
  }

  # Read in the output of mkvmerge
  exe=MKVMerge" --identify-verbose \""TempVideo"\""
  while ((exe | getline Line) > 0) {
    if (Debug) print "Debug|"Line
    FieldCount=split(Line, Fields)
    if (Fields[1]=="Track") {
      NoTr++
      Track[NoTr, "id"]=Fields[3]
      Track[NoTr, "typ"]=Fields[5]
      if (Track[NoTr, "typ"]=="audio") AudCnt++
      if (Track[NoTr, "typ"]=="subtitles") SubsCnt++
      for (i=6; i<=FieldCount; i++) {
        if (Fields[i]=="language") Track[NoTr, "lang"]=Fields[++i]
      }
    }
  }
  if (NoTr==0) {
    print "Error|No tracks found in \""TempVideo"\""
    exit
  }
  print "Info|Total tracks: "NoTr", Audio Tracks: "AudCnt", Subtitle Tracks: "SubsCnt
  for (i=1; i<=NoTr; i++) {
    #if (Debug) print "Debug|i:"i,"Track ID:"Track[i,"id"],"Type:"Track[i,"typ"],"Lang:"Track[i, "lang"]
    if (Track[i, "typ"]=="audio") {
      if (AudioKeep~Track[i, "lang"]) {
        if (Debug) print "Debug|Keep:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        if (AudioCommand=="") {
          AudioCommand=Track[i, "id"]
        } else {
          AudioCommand=AudioCommand","Track[i, "id"]
        }
      # Special case if there is only one audio track, even if it was not specified
      } else if(AudCnt==1) {
        if (Debug) print "Debug|Keeping only audio track:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        AudioCommand=Track[i, "id"]
      # Special case if there were multiple tracks, none were selected, and this is the last one.
      } else if(AudioCommand=="" && Track[i, "id"]==AudCnt) {
        if (Debug) print "Debug|Keeping last audio track:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        AudioCommand=Track[i, "id"]
      } else {
        if (Debug) print "Debug|\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
      }
    } else {
      if (Track[i, "typ"]=="subtitles") {
        if (SubsKeep~Track[i, "lang"]) {
          if (Debug) print "Debug|Keep:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
          if (SubsCommand=="") {
            SubsCommand=Track[i, "id"]
          } else {
            SubsCommand=SubsCommand","Track[i, "id"]
          }
        } else {
          if (Debug) print "Debug|\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        }
      }
    }
  }
  # This should never happen, but belt and suspenders
  if (AudioCommand=="") {
    CommandLine="-A"
  } else {
    CommandLine="-a "AudioCommand
  }
  if (SubsCommand=="") {
    CommandLine=CommandLine" -S"
  } else {
    CommandLine=CommandLine" -s "SubsCommand
  }
  if (Debug) print "Debug|Executing: "MKVMerge" --title \""Title"\" -q -o \""MKVVideo"\" "CommandLine" \""TempVideo"\""
  Result=system(MKVMerge" --title \""Title"\" -q -o \""MKVVideo"\" "CommandLine" \""TempVideo"\"")
  if (Result>1) print "Error|"Result" remuxing \""TempVideo"\""
}' | log

# Check for script completion and non-empty file
if [ -s "$NEWMOVIE" ]; then
  [ $DEBUG -eq 1 ] && echo "Debug|Deleting: \"$TEMPMOVIE\"" | log
  rm "$TEMPMOVIE" | log
else
  echo "Error|Unable to locate or invalid remuxed file: \"$NEWMOVIE\". Undoing rename." | log
  [ $DEBUG -eq 1 ] && echo "Debug|Renaming: \"$TEMPMOVIE\" to \"$MOVIE\"" | log
  mv "$TEMPMOVIE" "$MOVIE" | log
  exit 10
fi

# Call Radarr API to RescanMovie
if [ ! -z "$radarr_movie_id" ]; then
  if [ -f "$RADARR_CONFIG" ]; then
    # Inspired by https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
    read_xml () {
      local IFS=\>
      read -d \< ENTITY CONTENT
    }
    
    # Read Radarr config.xml
    while read_xml; do
      [[ $ENTITY = "Port" ]] && PORT=$CONTENT
      [[ $ENTITY = "UrlBase" ]] && URLBASE=$CONTENT
      [[ $ENTITY = "BindAddress" ]] && BINDADDRESS=$CONTENT
      [[ $ENTITY = "ApiKey" ]] && APIKEY=$CONTENT
    done < $RADARR_CONFIG
    
    [[ $BINDADDRESS = "*" ]] && BINDADDRESS=localhost
    
    [ $DEBUG -eq 1 ] && echo "Debug|Calling Radarr API 'RescanMovie' using movie id '$radarr_movie_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY'" | log
    # Calling API
    RESULT=$(curl -s -d "{name: 'RescanMovie', movieId: $radarr_movie_id}" -H "Content-Type: application/json" \
      -X POST http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY | jq -c '. | {JobId: .id, MovieId: .body.movieId, Message: .body.completionMessage, DateStarted: .queued}')
    [ $DEBUG -eq 1 ] && echo "Debug|API returned: $RESULT" | log
  else
    echo "Warn|Unable to locate Radarr config file: '$RADARR_CONFIG'" | log
    exit 12
  fi
else
  echo "Warn|Missing environment variable radarr_movie_id" | log
  exit 11
fi

[ $DEBUG -eq 1 ] && echo "Debug|Done" | log
