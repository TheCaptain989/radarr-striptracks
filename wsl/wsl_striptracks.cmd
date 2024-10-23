@ECHO OFF

REM This is a wrapper script for striptrack.sh that is meant to be called
REM by Radarr or Sonarr as a Custom Script.  It sets up the environment
REM and calls striptracks in a virtual Windows Subsystem for Linux (WSL).

setlocal enabledelayedexpansion enableextensions

REM Set the script execution root
set STRIPTRACKS_ROOT=%ProgramData%\striptracks
set WSLENV=STRIPTRACKS_ROOT/p:%WSLENV%

REM Pass the appropriate variables to WSL for each supported script mode
REM Check for radarr variable
if defined radarr_eventtype (
  cd %ProgramData%\Radarr
  set WSLENV=radarr_eventtype:radarr_moviefile_path/p:radarr_movie_path/p:radarr_movie_id:radarr_moviefile_id:radarr_movie_title:radarr_movie_year:%WSLENV%
)
REM Check for sonarr variable
if defined sonarr_eventtype (
  cd %ProgramData%\Sonarr
  set WSLENV=sonarr_eventtype:sonarr_episodefile_path/p:sonarr_series_path/p:sonarr_episodefile_episodeids:sonarr_episodefile_id:sonarr_series_id:sonarr_series_title:sonarr_episodefile_episodetitles:sonarr_episodefile_seasonnumber:sonarr_episodefile_episodenumbers:%WSLENV%
)

REM Add the log path so script logs show up in Radarr/Sonarr
set CMDLINEARGS=--log ./logs/striptracks.txt

REM Test for the STRIPTRACKS_ARGS variable and add the log option
REM but don't override if set manually
if defined STRIPTRACKS_ARGS (
  set WSLENV=STRIPTRACKS_ARGS:%WSLENV%
  REM Check for existing log option, both long and short
  echo "%STRIPTRACKS_ARGS%" | find "--log " >nul
  if ERRORLEVEL 1 (
    echo "%STRIPTRACKS_ARGS%" | find "-l " >nul
    if ERRORLEVEL 1 (
      REM No log option, so add it
      set STRIPTRACKS_ARGS=%STRIPTRACKS_ARGS% %CMDLINEARGS%
      set CMDLINEARGS=
    )
  )
)

REM Call striptracks script using WSL
REM Pass command-line arguments if they exist
wsl $STRIPTRACKS_ROOT/striptracks.sh %CMDLINEARGS% %*
