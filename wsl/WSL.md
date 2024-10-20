# About
This mod is able to run on Windows versions of Radarr and Sonarr by using the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/).
Limited support is available.

# Installation
Below are highly simplified installation instructions assuming defaults on a basic system.  Your specific system may require changing paths or other alterations.

1. Install Radarr or Sonarr on Windows
2. Install WSL from PowerShell:

    ```powershell
    wsl --install
    ```

3. Install the required Linux modules:

    ```powershell
    wsl sudo bash -c "apt update && apt install mkvtoolnix jq"
    ```

4. Download the **[striptracks.sh](../usr/local/bin/striptracks.sh)** mod script and the required **[wsl_striptracks.cmd](https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/master/wsl/wsl_striptracks.cmd)**
wrapper script and save them to a new **%ProgramData%\striptracks** directory:

    ```powershell
    mkdir %ProgramData%\striptracks
    cd %ProgramData%\striptracks
    Invoke-WebRequest https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/master/wsl/wsl_striptracks.cmd -OutFile wsl_striptracks.cmd
    wsl bash -c "wget https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/master/root/usr/local/bin/striptracks.sh && chmod +x striptracks.sh"
    ```

5. Continue with Installation step 3 in the previous [README](../README.md#installation).

## What's Going on Here?
WSL provides a way to run a virtual Linux machine on Windows.  The script and supporting MKVToolNix package are running in the virtual machine
and Windows makes the magic possible to have them interroperate.

## Requirements
- This requires WSL v2 and has only been tested on Windows 11 23H2.
- Your Radarr/Sonarr configurations are stored under your `%ProgramData%` directory (by default, these are C:\ProgramData\Radarr or C:\ProgramData\Sonarr).
