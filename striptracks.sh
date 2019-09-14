#!/bin/bash

# Adapated and corrected from Endoro's post 1/5/2014:
#  https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889
#
# Put a colon `:` in front of every language code.  Expects ISO639-2 codes

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
    echo $(date +"%F %T")\|"$REPLY" >>"$LOG"
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
      MSG="DEBUG: Enabling debug logging."
      echo "$MSG" | log
      echo "$MSG"
      ENVLOG=/config/logs/debugenv.txt
      echo "--------$(date +"%F %T")--------" >>"$ENVLOG"
      printenv | sort >>"$ENVLOG"
    ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$MOVIE" ]; then
  MSG="ERROR: No movie file specified! Not called from Radarr?"
  echo "$MSG" | log
  echo "$MSG"
  usage 
  exit 1
fi

if [ ! -f "$MOVIE" ]; then
  MSG="ERROR: Input file not found: \"$MOVIE\""
  echo "$MSG" | log
  echo "$MSG"
  exit 5
fi

if [ -z "$1" ]; then
  MSG="ERROR: No audio languages specified!"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 2
fi

if [ -z "$2" ]; then
  MSG="ERROR: No subtitles languages specified!"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 3
fi

echo "Radarr event: $radarr_eventtype|Movie: $MOVIE|AudioKeep: $1|SubsKeep: $2" | log
awk '
BEGIN {
  MKVMerge="/usr/bin/mkvmerge"
  FS="[\t\n: ]"
  IGNORECASE=1
  OrgVideo=ARGV[1]
  TempVideo=ARGV[2]
  MKVVideo=ARGV[3]
  AudioKeep=ARGV[4]
  SubsKeep=ARGV[5]
  Title=substr(MKVVideo, 1, length(MKVVideo)-4)
  sub(".*/", "", Title)
  if (match(Title,/[a-zA-Z0-9]- /)) {
    Arr[1]=substr(Title,1,RSTART)
    Arr[2]=substr(Title,RSTART+RLENGTH-1)
    Title=Arr[1]":"Arr[2]
  }  # mawk does not have gensub function

  print "Renaming: \""OrgVideo"\" to \""TempVideo"\""
  Result=system("mv \""OrgVideo"\" \""TempVideo"\"")
  if (Result) {
    print "ERROR: "Result" renaming \""OrgVideo"\""
    exit
  }

  exe=MKVMerge" --identify-verbose \""TempVideo"\""
  while ((exe | getline Line) > 0) {
    print Line
    FieldCount=split(Line, Fields)
    if (Fields[1]=="Track") {
      NoTr++
      Track[NoTr, "id"]=Fields[3]
      Track[NoTr, "typ"]=Fields[5]
      if (Track[NoTr, "typ"]=="audio") AudCnt++
      for (i=6; i<=FieldCount; i++) {
        if (Fields[i]=="language") Track[NoTr, "lang"]=Fields[++i]
      }
    }
  }
  if (NoTr==0) {
    print "ERROR: No tracks found in "TempVideo"."
    exit
  }
  print "Tracks: "NoTr", Audio Tracks: "AudCnt
  for (i=1; i<=NoTr; i++) {
    #print "i:"i,"Track ID:"Track[i,"id"],"Type:"Track[i,"typ"],"Lang:"Track[i, "lang"]
    if (Track[i, "typ"]=="audio") {
      if (AudioKeep~Track[i, "lang"]) {
        print "Keep:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        if (AudioCommand=="") {
          AudioCommand=Track[i, "id"]
        } else {
          AudioCommand=AudioCommand","Track[i, "id"]
        }
      } else if(AudCnt==1) {
        print "Keeping only audio track:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        AudioCommand=Track[i, "id"]
      } else if(AudioCommand=="" && Track[i, "id"]==AudCnt) {
        print "Keeping last audio track:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        AudioCommand=Track[i, "id"]
      } else {
        print "\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
      }
    } else {
      if (Track[i, "typ"]=="subtitles") {
        if (SubsKeep~Track[i, "lang"]) {
          print "Keep:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
          if (SubsCommand=="") {
            SubsCommand=Track[i, "id"]
          } else {
            SubsCommand=SubsCommand","Track[i, "id"]
          }
        } else {
          print "\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        }
      }
    }
  }
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
  print "Executing: "MKVMerge" --title \""Title"\" -q -o \""MKVVideo"\" "CommandLine" \""TempVideo"\""
  Result=system(MKVMerge" --title \""Title"\" -q -o \""MKVVideo"\" "CommandLine" \""TempVideo"\"")
  if (Result>1) print "ERROR: "Result" remuxing \""TempVideo"\""
}' "$MOVIE" "$TEMPMOVIE" "$NEWMOVIE" "$1" "$2" | log

# Check for script completion and non-empty file
if [ -s "$NEWMOVIE" ]; then
  echo "Deleting: \"$TEMPMOVIE\"" | log
  rm "$TEMPMOVIE" | log
else
  echo "ERROR: Unable to locate or invalid remuxed file: \"$NEWMOVIE\". Undoing rename." | log
  echo "Renaming: \"$TEMPMOVIE\" to \"$MOVIE\"" | log
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
    
    echo "Calling Radarr API 'RescanMovie' using movie id '$radarr_movie_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY'" | log
    # Calling API
    RESULT=$(curl -s -d "{name: 'RescanMovie', movieId: $radarr_movie_id}" -H "Content-Type: application/json" \
      -X POST http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY | jq -c '. | {JobId: .id, MovieId: .body.movieId, Message: .body.completionMessage, DateStarted: .queued}')
    echo "API returned: $RESULT" | log
  else
    echo "ERROR: Unable to locate Radarr config file: '$RADARR_CONFIG'" | log
    exit 12
  fi
else
  echo "ERROR: Missing environment variable radarr_movie_id" | log
  exit 11
fi

echo "Done" | log
