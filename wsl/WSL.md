# About
This mod is able to run on Windows versions of Radarr and Sonarr by using the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/).

# Installation
Below are highly simplified installation instructions assuming defaults on a basic system.  Your specific system may require changing paths or other wrapper script alterations.

1. Install Radarr or Sonarr on Windows
2. Install WSL from PowerShell:

   ```powershell
   wsl --install
   ```

3. Run the [wsl-install-striptracks.ps1](./wsl-install-striptracks.ps1)
installation script, entering your Linux user password when prompted:

   ```powershell
   iex (iwr "https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/master/wsl/wsl-install-striptracks.ps1").Content
   ```

> [!NOTE]
> The password entered here is *only* used to execute sudo once to install required Linux packages.  It is not stored or saved anywhere.

   The installation script supports optional command-line arguments to change the default branch, installation directory, etc.

   <details>
   <summary>Command-Line Arguments</summary>

   Option|Argument|Description
   ---|---|---
   `-Password`|`<SecureString>`|Your WSL Linux user password.<br/>Must be a PowerShell `[SecureString]` data type.
   `-Directory`|`<path>`|Directory to install striptracks to<br/>Default: `C:\ProgramData\striptracks`
   `-Owner`|`<name>`|GitHub repository owner<br/>Default: `TheCaptain989`
   `-Repository`|`<name>`|GitHub repository name<br/>Default: `radarr-striptracks`
   `-Release`|`<string>`|GitHub branch of source code to download<br/>Default: `latest`
   `-GhApiRoot`|`<url>`|GitHub API root URL<br/>Default: `https://api.github.com`

   To pass command-line arguments to the script, you must download it and execute it in multiple separate steps.

   *Example Command-Line Argument Use*

   ```powershell
   # Step 1: Download the script
   Invoke-WebRequest "https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/refs/heads/master/wsl/wsl-install-striptracks.ps1" -OutFile wsl-install-striptracks.ps1
   # Step 2: Needed to run unsigned downloaded scripts
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser  
   # Step 3: Execute installation script.  Example option only.
   .\wsl-install-striptracks.ps1 -Directory "D:\striptracks"
   ```

   </details>

4. Configure a custom script from Radarr's or Sonarr's *Settings* > *Connect* screen and type the following in the **Path** field:  
   `C:\ProgramData\striptracks\wsl-striptracks.cmd`  

   <details>
   <summary>Screenshot</summary>

   *New Custom Script Example*  
   ![wsl custom script](wsl-custom-script.png "New Custom Script")

   <detials>

# Explanation
WSL provides a way to run a virtual Linux machine on Windows.  The script and supporting MKVToolNix package are running in the virtual machine
and WSL makes the magic possible to have them interoperate.

# Requirements
- This requires WSL v2.
- This has only been tested on Windows 11 23H2.
- Only one instance each of Radarr and Sonarr are supported.
- The Radarr/Sonarr configurations must be stored under the `%ProgramData%` directory (by default, these are C:\ProgramData\Radarr or C:\ProgramData\Sonarr).
