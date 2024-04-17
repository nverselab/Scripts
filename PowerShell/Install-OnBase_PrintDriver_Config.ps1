# Build Log Folder

if (!(Test-Path -Path "C:\IntuneLogs")) {

    New-Item -Path "C:\IntuneLogs" -ItemType Directory

    }

Start-Transcript -Path "C:\IntuneLogs\OnBase-Script.log"

# Variables
$OnBaseInstaller = "$PSScriptRoot\HylandUnityClient.msi"
$PrintDriverInstaller = "$PSScriptRoot\HylandOnBaseVirtualPrintDriverx64.msi"
$OnBaseConfig = "obunity.exe.config"
$OnBaseConfigPath = "C:\Program Files (x86)\Hyland\Unity Client"
$VCdistPath = "$PSScriptRoot\prerequisits\visualcplusplus"
$dotNetPath = "$PSScriptRoot\prerequisits\dotNet"

# Start VC++ Redist Installs
## Get the list of .exe files in the directory
$vcFiles = Get-ChildItem -Path $VCdistPath -Filter "*.exe"

## Run each .exe file with the /Q argument
foreach ($vcFile in $vcFiles) {
    write-host "Running $vcFile"
    Start-Process -FilePath $vcFile.FullName -ArgumentList "/Q /norestart" -Wait
}

# Start .Net 4.8 Install
## Get the list of .msi files in the directory
$dotNetFiles = Get-ChildItem -Path $dotNetPath -Filter "*.exe"

## Run each .exe file with the silent argument
foreach ($dotNetFile in $dotNetFiles) {
    write-host "running $dotNetPath\$dotNetFile"
    Start-Process -FilePath $dotNetFile.FullName -ArgumentList "/install /quiet /norestart" -Wait
}

# Start OnBase Install
write-host "Installing $OnBaseInstaller"
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$OnBaseInstaller`" /quiet /l*v `"C:\IntuneLogs\OnBase-Installer.log`"" -Wait
write-host "Installing $PrintDriverInstaller"
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$PrintDriverInstaller`" /quiet /l*v `"C:\IntuneLogs\OnBase-PrintDriver.log`"" -Wait -ErrorAction SilentlyContinue

# Overwrite Config File
write-host "Copying $PSScriptRoot\$OnBaseConfig to $OnBaseConfigPath"
Copy-Item -Path $PSScriptRoot\$OnBaseConfig -Destination $OnBaseConfigPath -Force

$sourceHash = Get-FileHash -Path $PSScriptRoot\$OnBaseConfig -Algorithm MD5
$destinationHash = Get-FileHash -Path (Join-Path $OnBaseConfigPath (Get-Item $OnBaseConfig).Name) -Algorithm MD5
if ($sourceHash.Hash -eq $destinationHash.Hash) {
    Write-Host "File copied successfully."
} else {
    Write-Host "File copy verification failed."
}

Stop-Transcript
