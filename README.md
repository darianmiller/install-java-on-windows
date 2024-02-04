# install-java-on-windows
PowerShell script to install the [Java JDK](https://projects.eclipse.org/projects/adoptium.temurin) (Elipse) from a binary release zip on Windows.

- No dependencies
- MIT Licensed
- You can manually download the binary release zips from [Adoptium](https://adoptium.net/temurin/releases/?version=17&os=windows&arch=x64&package=jdk)
- Associated blog article can be found here: https://ideasawakened.com

# Summary

You can simply run the script with the DownloadLatest switch (`Install-Java-On-Windows.ps1 -DownloadLatest`) and the latest release zip will be downloaded and automatically installed to `C:\Java` (overwriting existing version, if present.)  Alternately, manually download the latest release zip and provide the filename via the ArchiveFileName parameter. (`Install-Java-On-Windows.ps1 -ArchiveFileName OpenJDK17U-jdk_x64_windows_hotspot_17.0.10_7.zip`)

Note: Currently downloading the latest `Java 17 LTS` release.

# Parameters

Note: you need to provide at least one parameter as you must either specify the `ArchiveFileName` or the `DownloadLatest` switch.

## ArchiveFileName
This string parameter is the release zip to install (as previously downloaded from Adoptium.)  An example of the current latest release zip is `OpenJDK17U-jdk_x64_windows_hotspot_17.0.10_7.zip` which is 181MB in size.

## DestinationPath
This optional string parameter is the path to unzip the binaries into and it defaults to `C:\Java` if not provided. 

## DownloadLatest
If specified, this optional switch parameter overrides the ArchiveFileName and the latest release zip will be downloaded from GitHub and installed.  The archive file will be saved within the TEMP folder and deleted once the installation is completed.

## UpdatePath
If this optional switch is specified, the script will update the PATH with the Java folder (useful if you are running command line tools.)