<#
.Synopsis
  This script installs striptracks.sh in a Windows Subsystem for Linux (WSL) environment.
.Description
  radarr-striptracks is a Docker Mod for the Linuxserver.io Radarr/Sonarr containers.
  This installation script makes it work outside of Docker in a virtual WSL environment
  on Windows.
.Link
  https://github.com/TheCaptain989/radarr-striptracks
.Example
  wsl-install-striptracks "SudoPassword"
#>

#requires -Version 3

[CmdletBinding()]
#region Initialize parameters
param (
    # WSL user password (for sudo command)
    # This is not stored and only used to pass to sudo for required package installations
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName)]
    [string]$Password,

    # Directory to install striptracks to
    [string]$Directory = "$env:ProgramData\striptracks",

    # GitHub branch of source code to download
    [string]$Branch = "master",

    # GitHub download path for WSL wrapper scripts for striptracks
    [string]$Webroot = "https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/$Branch"
)
#endregion

# Initial parameters
$ModVersion="2.9.0-wsl"   # Working on a better way to set this

function Check-WSL {
  # Check that wsl is installed
  wsl --status
  if ($LASTEXITCODE -eq 50) {
      Write-Error -Message "WSL does not appear to be installed.  Run 'wsl --install' first."
      if (-not $Host.Interactive) { exit 1 } else return 0
  }
  return 1
}

function Prep-WSL {
  # Install the required Linux packages
  wsl -- echo "$Password" `| sudo -S bash -c "apt update && apt install mkvtoolnix jq"
  if ($LASTEXITCODE -ne 0) {
      Write-Error -Message "There was an error when attempting to install required Linux packages."
      if (-not $Host.Interactive) { exit 1 } else return 0
  }
  return 1
}

if ((Check-WSL) -and (Prep-WSL)) {
  # Create the new directory
  New-Item -ItemType Directory $Directory | Set-Location

  # Get the list of WSL wrapper script(s)
  $CmdFiles = Invoke-WebRequest -Uri "$Webroot/wsl/" -Method Head | Select-Object -ExpandProperty Links | Where-Object { $_.Href -like "wsl-striptracks*.cmd" }

  # Download each file
  foreach ($file in $CmdFiles) {
      $Url = "$Webroot/wsl/" + $file.Href
      Invoke-WebRequest -Uri $Url -OutFile $file.Href
  }

  # Download the striptracks.sh script and make it executable
  wsl bash -c "wget $Webroot/root/usr/local/bin/striptracks.sh && chmod +x striptracks.sh && sed -i -e 's/{{VERSION}}/$ModVersion/' striptracks.sh"

  Write-Output "striptracks has been installed."
}