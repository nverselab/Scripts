# Variables
$biosPassword="yourBiosPassword"
$logPath="C:\path\to\log.log"
$deferralHours="1"
$maxDeferrals="3"

# Dell Command | Update CLI Documentation: https://www.dell.com/support/manuals/en-us/command-update/dcu_rg/dell-command-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us

# Check if the log directory exists, if not, create it
$logDirectory = [System.IO.Path]::GetDirectoryName($logPath)
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force
}

# Configure the Dell Command | Update Agent
    # BIOS Password set by configuration is only required once and not subsequently for each command run.
    # Make sure the GUI is closed when running CLI commands.  Not meant to be open during these actions.

dcu-cli.exe /configure -updateType=bios -scheduleManual -installationDeferral=enable -deferralInstallInterval=$deferralHours -deferralInstallCount=$maxDeferrals -biosPassword=$biosPassword

# BIOS Update Command for a one-time update - will respect previous configurations for deferrals and password

dcu-cli.exe /applyUpdates -updateType=bios -silent -outputlog=$logPath
