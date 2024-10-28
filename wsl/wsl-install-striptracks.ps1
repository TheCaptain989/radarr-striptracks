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
  wsl-install-striptracks -Release "v2.9.0"

  This changes the default release.
#>

#requires -Version 3

[CmdletBinding(PositionalBinding = $False)]
#region Initialize parameters
param (
    # WSL user password (for sudo command)
    # This is not stored and only used to pass to sudo for required package installations
    [Parameter(Mandatory = $true, HelpMessage = "Enter your WSL user password (this will not be stored)")]
    [securestring]$Password = (Read-Host -AsSecureString "Enter your WSL user password (this will not be stored)"),

    # Directory to install striptracks to
    [string]$Directory = "$env:ProgramData\striptracks",

    # GitHub repository owner
    [string]$Owner = "TheCaptain989",

    # GitHub repository name
    [string]$Repository = "radarr-striptracks",

    # GitHub respository release tag
    [string]$Release = "latest",

    # GitHub API root URL
    [string]$GhApiRoot = "https://api.github.com"
)
#endregion

# Uneditable initial parameters
$GhApiHeaders = @{"Accept"="application/vnd.github+json"; "X-GitHub-Api-Version"="2022-11-28"}
$ZipFile = "striptracks-$Release.zip"

# Functions
function Test-WSL {
  # Check that WSL is installed
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

# Save working directory
$OrgDirectory = $pwd

# Check that WSL is installed
Write-Output "Checking WSL status..."
if ((Test-WSL) -ne 0) { return }

# Install the required Linux packages
Write-Output "Installing required Linux packages..."
if ((Install-LinuxPackages) -ne 0) { return }

# Create the new directory if it doesn't already exist and change to it
if (-not (Test-Path $Directory)) {
    Write-Output "Creating $Directory"
    New-Item -ItemType Directory $Directory | Out-Null
}
Set-Location $Directory

# Query GitHub for release version
Write-Output "Getting striptracks release info..."
$ApiResponse = (Invoke-WebRequest -Headers $GhApiHeaders -Uri "$GhApiRoot/repos/$Owner/$Repository/releases/$Release").Content | ConvertFrom-Json
$ModVersion = $ApiResponse.tag_name

# Download striptracks ZIP archive
Write-Output "Downloading striptracks ZIP archive..."
Invoke-WebRequest -Headers $GhApiHeaders -Uri $ApiResponse.zipball_url -OutFile "$Directory\$ZipFile"

# Unzip files
Write-Output "Extracting files from ZIP archive..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ZipObj = [System.IO.Compression.ZipFile]::OpenRead("$Directory\$ZipFile")
$ZipEntries = $ZipObj.Entries | Where-Object { $_.FullName -like "*/wsl/wsl-*.cmd" -or $_.Name -eq "striptracks.sh" }
foreach ($Entry in $ZipEntries) {
  [IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $Entry.Name, $true)
  # Some file specific edits are required
  switch ($Entry.Name) {
    "wsl-striptracks.cmd" {
      (Get-Content -Path $Entry.Name) -replace "set STRIPTRACKS_ROOT=%ProgramData%\\striptracks", "set STRIPTRACKS_ROOT=$Directory" | Set-Content -Path $Entry.Name
    }
    "striptracks.sh" {
      Set-Content $Entry.Name -NoNewline -Value (((Get-Content -Path $Entry.Name) -replace "{{VERSION}}", $ModVersion -join "`n") + "`n")
    }
  }
}

# Close and remove the ZIP archive
Write-Output "Deleting ZIP archive"
$ZipObj.Dispose()
Remove-Item -Path "$Directory\$ZipFile"

# Make the striptracks.sh script executable
Write-Output "Making striptracks.sh executable"
wsl chmod +x striptracks.sh

# Exit
Set-Location -Path $OrgDirectory.Path
Write-Output "striptracks has been installed to $Directory"
