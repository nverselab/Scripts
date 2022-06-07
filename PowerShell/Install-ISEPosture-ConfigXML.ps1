if (!(Test-Path -Path "C:\IntuneLogs")) {

    New-Item -Path "C:\IntuneLogs" -ItemType Directory

    }

Start-Transcript -Path "C:\IntuneLogs\ISE-Posture-Module-Script.log"

Set-Location -ErrorAction Stop -LiteralPath $PSScriptRoot

## Check if AnyConnect Core has finished installing and wait 60 seconds

$AnyConnectPath = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe"

if (Test-Path -Path $AnyConnectPath) {

    Write-Host "AnyConnect Core Agent found... waiting 60 seconds before starting Posture Module install..."
    Start-Sleep 60

    }

Else {

    Write-Host "AnyConnect Core Agent not found... waiting 60 seconds in case it's still finishing up..."
    Start-Sleep 60

    }

## Start Posture Module install with logging

$logpath = "C:\IntuneLogs\ISE-Posture-Module-Install.log"

Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/i anyconnect-win-4.10.05095-iseposture-predeploy-k9.msi /qn /l*i $($logpath)" -Wait

## Check to see if agent installed and wait 60 seconds for it to finish up.

$PostureApp = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\aciseposture.exe"

if (Test-Path -Path $PostureApp) {

    Write-Host "$PostureApp found... Continuing after 60 seconds."

    }

Else {

    Write-Host "$PostureApp not found... waiting 60 seconds to allow the install to finish just in case."
    Start-Sleep 60

    }

## Copy the config file to the appropriate path and validate

$Destination = "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\ISE Posture"
$ExpectedFilePath = "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\ISE Posture\ISEPostureCFG.xml"

if (!(Test-Path -path $Destination)) {

    Write-Host "$Destination does not exist.  Creating it before copying the config file..."
    New-Item $Destination -Type Directory
    
    }

Copy-Item -Path $PSScriptRoot/ISEPostureCFG.xml -Destination $Destination -Force

if (Test-Path -path $ExpectedFilePath) {

    Write-Host "Config file copied successfully."

    }

Else {

    Write-Host "Config file not found in $Destination.  Exiting unsuccessfully..."
    Exit 1

    }

Stop-Transcript