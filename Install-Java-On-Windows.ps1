<#
.Synopsis
   Install Java on Windows from a binaries zipfile as published by Adoptium  

.EXAMPLE
   Extract the latest release zip to 'C:\Java' 
   Install-Java-On-Windows.ps1 -ArchiveFileName OpenJDK17U-jdk_x64_windows_hotspot_17.0.10_7.zip

.EXAMPLE
   Download the latest version and install to 'C:\Java' 
   Install-Java-On-Windows.ps1 -DownloadLatest

.EXAMPLE
   Extract the release zip named 'Latest.zip' to 'C:\Server\Java' 
   Add C:\Server\Java to the system PATH environment variable
   Install-Java-On-Windows.ps1 -ArchiveFileName Latest.zip -DestinationPath C:\Server\Java -UpdatePath

.NOTES
   Latest version of this PowerShell script is on GitHub: https://github.com/darianmiller/install-java-on-windows 
   Version 1.0 2024-02-04 Darian Miller
   MIT Licensed

.Parameter ArchiveFileName
    Specify full path of Java JDK binaries release zip filename (or use the DownloadLatest switch)

.Parameter DestinationPath
    Specify path to destination folder, defaults to 'C:\Java'

.Parameter DownloadLatest
    Optional switch to download latest version from GitHub (can be used instead of specifying archive file)

.Parameter UpdatePath
    Optional switch to add the Java folder to the PATH environment variable
#>


param(
  [string]$ArchiveFileName,
  [string]$DestinationPath = "C:\Java",
  [switch]$DownloadLatest,
  [switch]$UpdatePath
)


function CreateJavaRootFolder {
  param (
    [string]$FolderName
  )
  if (-not (Test-Path $FolderName -PathType Container)) {

    Write-Host "- Creating JAVA root folder: $FolderName"

    New-Item -ItemType Directory -Path $FolderName | Out-Null
  }
  else {

    Write-Warning "- Note: Will overwrite files in existing folder: '$FolderName'"

  }
}

function Unzip {
  param (
    [string]$ArchiveFileName,
    [string]$DestinationPath,
    [int]$StripLevels = 1
  )

  Write-Host "- Extracting archive file '$ArchiveFileName' to '$DestinationPath'"

  #https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/expand-archive
  #Built-in powershell functionality currently doesn't exist to strip the root folder, using tar instead of extracting to temp folder and copying which appears to be the common workaround
  #Expand-Archive -Path $ArchiveFileName -DestinationPath $Destination -Force
  tar -xf $ArchiveFileName --strip-components=$StripLevels -C $DestinationPath

  if ($LASTEXITCODE -ne 0) {

    throw "ERROR: Failed to extract '$ArchiveFileName', TAR exit code '$LASTEXITCODE'"

  } 
}


function SetEnvironmentVariables {
  param (
    [string]$JavaHomePath
  )
  $currentEnv = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
  if ($currentEnv -ne $javaHomePath) {

    Write-Host "- Setting JAVA_HOME environment variable to: '$javaHomePath'"

    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHomePath, [System.EnvironmentVariableTarget]::Machine)
  }
  else {

    Write-Verbose "Note: JAVA_HOME is already set to '$currentEnv'"

  }

  $currentEnv = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
  Write-Verbose "Current PATH: '$currentEnv'"
  if ($currentEnv -notlike "*$javaHomePath*") {
    $newPath = "$currentEnv;$javaHomePath"

    Write-Host "- Adding Java root folder system PATH: '$javaHomePath'"
    Write-Verbose "New system PATH will be: '$newPath'"

    [Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Machine)
  }
  else {

    Write-Verbose "Note: System PATH already contains '$javaHomePath'"

  }
}

function DownloadLatestReleaseFromGitHub {

  $Result = ""

  Write-Host "- Attempting to download latest version"

  #As of Jan 31, 2024, the latest version is: "OpenJDK17U-jdk_x64_windows_hotspot_17.0.10_7.zip" 190MB

  $repo = "adoptium/temurin17-binaries"

  #Could potentially support other OS/Bitness, but no desire at this point
  $filenamePattern = "*jdk_x64_windows_hotspot*.zip"
  $releasesUri = "https://api.github.com/repos/$repo/releases/latest"

  Write-Verbose "Getting list of release binary packages from '$releasesUri'"

  $downloadUri = ((Invoke-RestMethod -Method GET -Uri $releasesUri).assets | Where-Object name -like $filenamePattern).browser_download_url

  Write-Verbose "- Latest JDK from '$repo' on GitHub determined to be: '$downloadUri'"

  if ($downloadUri -ne "") {

    Write-Host "- Downloading release zip"

    $Result = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $(Split-Path -Path $downloadUri -Leaf)

    Write-Verbose "Temporary file to be created: '$Result'"

    Invoke-WebRequest -Uri $downloadUri -Out $Result        
  }
  else {

    Throw "ERROR: Could not determine latest release from '$downloadUri' (GitHub issues or an update of this script is required)"

  }

  return $Result
}


function AllDone_ShowVersion {

  Write-Host "- SUCCESS: Java binaries installed!" -ForegroundColor Green

  $javaExec = Join-Path $DestinationPath "bin\java.exe"

  if (Test-Path $javaExec -PathType Leaf) {

    Write-Host
    Write-Host "Displaying version details from 'java -version'"

    # Redirect std error (2) into std output (1) and display any lines of text with "version" 
    & $javaExec -version 2>&1 | Select-String "version"
  }
  else {

    throw "ERROR: Java binary not found: '$javaExec'"

  }
}


function Main {

  Write-Host 
  CreateJavaRootFolder -FolderName $DestinationPath

  if ($DownloadLatest) {

    $tempFile = DownloadLatestReleaseFromGitHub
    if ($tempFile -ne "") {
      try {
        Unzip -ArchiveFileName $tempFile -DestinationPath $DestinationPath -StripLevels 1
      }
      finally {
        if (Test-Path -Path $tempFile -PathType Leaf) {

          Write-Verbose "Removing Temporary download file: '$tempFile'"

          Remove-Item $tempFile -Force
        }
      }
    }
  }
  else {    
    if ($ArchiveFileName -ne "") {
      Unzip -ArchiveFileName $ArchiveFileName -DestinationPath $DestinationPath -StripLevels 1
    }
    else {

      Throw "ArchiveFileName (or downloadLatest switch) not specified"

    }
  }

  if ($UpdatePath) {
    SetEnvironmentVariables -JavaHomePath $DestinationPath
  }

  AllDone_ShowVersion
}


Main;