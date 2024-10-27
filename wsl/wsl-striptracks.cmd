@echo off
rem This is a wrapper script for striptrack.sh that is meant to be called
rem by Radarr or Sonarr as a Custom Script.  It sets up the environment
rem and calls striptracks in a virtual Windows Subsystem for Linux (WSL).
rem  https://github.com/TheCaptain989/radarr-striptracks/

rem Seemingly ubiquitous required batch file localization
setlocal enableextensions enabledelayedexpansion

rem Set the script execution root
set STRIPTRACKS_ROOT=%ProgramData%\striptracks

rem WSLENV is a special environment variable that can pass values
rem back and forth and translate file and directory paths between
rem Windows and Linux
set WSLENV=STRIPTRACKS_ROOT/p:%WSLENV%

rem Pass the appropriate variables to WSL for each supported script mode
rem Uses the default ProgramData location for Radarr/Sonarr configuration
rem Check for radarr variable
if defined radarr_eventtype (
  cd %ProgramData%\Radarr
  set WSLENV=radarr_eventtype:radarr_moviefile_path/p:radarr_movie_path/p:radarr_movie_id:radarr_moviefile_id:radarr_movie_title:radarr_movie_year:%WSLENV%
)
rem Check for sonarr variable
if defined sonarr_eventtype (
  cd %ProgramData%\Sonarr
  set WSLENV=sonarr_eventtype:sonarr_episodefile_path/p:sonarr_series_path/p:sonarr_episodefile_episodeids:sonarr_episodefile_id:sonarr_series_id:sonarr_series_title:sonarr_episodefile_episodetitles:sonarr_episodefile_seasonnumber:sonarr_episodefile_episodenumbers:%WSLENV%
)

rem Add the log path so script logs show up in Radarr/Sonarr
set CMDLINEARGS=--log ./logs/striptracks.txt

rem Test for the STRIPTRACKS_ARGS variable and add the log option
rem but don't override if it is already present
if defined STRIPTRACKS_ARGS (
  set WSLENV=STRIPTRACKS_ARGS:%WSLENV%
  rem Check for existing log option, both long and short
  echo "%STRIPTRACKS_ARGS%" | find "--log " >nul
  if errorlevel 1 (
    echo "%STRIPTRACKS_ARGS%" | find "-l " >nul
    if errorlevel 1 (
      rem No log option, so add it
      set STRIPTRACKS_ARGS=%STRIPTRACKS_ARGS% %CMDLINEARGS%
      set CMDLINEARGS=
    )
  )
)

rem Call striptracks.sh script using WSL
rem Pass command-line arguments if they exist
wsl $STRIPTRACKS_ROOT/striptracks.sh %CMDLINEARGS% %*
