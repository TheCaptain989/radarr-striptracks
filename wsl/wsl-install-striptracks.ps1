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
  wsl-install-striptracks -Branch "develop"

  This changes the default branch.
#>

#requires -Version 3

[CmdletBinding(PositionalBinding = $False)]
#region Initialize parameters
param (
    # WSL user password (for sudo command)
    # This is not stored and only used to pass to sudo for required package installations
    [Parameter(Mandatory = $true, HelpMessage = "Enter your WSL user password (this will not be stored)")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='Linter erroneously says this is not used')]
    [securestring]$Password = (Read-Host -AsSecureString "Enter your WSL user password (this will not be stored)"),

    # Directory to install striptracks to
    [string]$Directory = "$env:ProgramData\striptracks",

    # GitHub branch of source code to download
    [string]$Branch = "master",

    # GitHub download URL for striptracks
    [string]$Webroot = "https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/$Branch"
)
#endregion

begin {
    # Initial parameters
    $ModVersion = "2.9.0-wsl"   # Working on a better way to set this
    $CmdFiles = @("wsl-striptracks.cmd", "wsl-striptracks-debug.cmd")   # List of WSL wrapper script(s)

    # Functions
    function Test-WSL {
      # Check that wsl is installed
      $local:WSLStatus = wsl --status
      if ($LASTEXITCODE -ne 0) {
        switch ($LASTEXITCODE) {
            50 { Write-Error -Message "WSL does not appear to be installed.  Run 'wsl --install' first." -Category NotInstalled -TargetObject $WSLStatus }
            default { Write-Error -Message "Error $LASTEXITCODE when attempting to check WSL status." -TargetObject $WSLStatus }
        }
      }
      return $LASTEXITCODE
    }

    function Install-LinuxPackages {
      # Install the required Linux packages
      $local:PlanTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
      $local:WSLStatus = wsl -- echo "$PlanTextPassword" `| sudo -S bash -c "apt update && apt install mkvtoolnix jq" 2>&1
      if ($LASTEXITCODE -ne 0) {
          switch ($LASTEXITCODE) {
            1 { Write-Error -Message "Your password is incorrect." -Category AuthenticationError -TargetObject $WSLStatus }
            default { Write-Error -Message "Error $LASTEXITCODE when attempting to install required Linux packages." -TargetObject $WSLStatus }
          }
      }
      return $LASTEXITCODE
    }
}

process {
    $OrgDirectory = $pwd

    Write-Output "Checking WSL status..."
    if ((Test-WSL) -ne 0) { return }

    Write-Output "Installing required Linux packages..."
    if ((Install-LinuxPackages) -ne 0) { return }

    # Create the new directory if it doesn't already exist
    if (-not (Test-Path $Directory)) {
        Write-Output "Creating $Directory"
        New-Item -ItemType Directory $Directory | Out-Null
    }
    Set-Location $Directory

    # Download WSL wrapper scripts
    Write-Output "Downloading wrapper scripts $($CmdFiles -join ", ")"
    try {
        foreach ($File in $CmdFiles) {
            $Url = "$Webroot/wsl/" + $File
            Invoke-WebRequest -Uri $Url -OutFile $File
        }
    } catch {
        Write-Error -Message "Unable to download wrapper scripts from $Webroot/wsl/" -Category ConnectionError
        return
    }

    # Download the striptracks.sh script and make it executable
    Write-Output "Downloading striptracks.sh"
    wsl bash -c "wget -qO striptracks.sh $Webroot/root/usr/local/bin/striptracks.sh && chmod +x striptracks.sh && sed -i -e 's/{{VERSION}}/$ModVersion/' striptracks.sh"
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message "Unable to download and configure striptracks.sh from $Webroot/root/usr/local/bin" -Category ConnectionError
        return
    }

    Set-Location -Path $OrgDirectory.Path
    Write-Output "striptracks has been installed to $Directory"
}