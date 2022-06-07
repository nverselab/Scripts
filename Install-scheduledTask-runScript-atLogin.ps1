# Contents of Script to Run Webpage in Kiosk mode and Keep screen awake
$TaskScript ='Start-Process -FilePath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList "--kiosk https://google.com --edge-kiosk-type=fullscreen"

Clear-Host
Echo "...Lock screen avoider..."

$WShell = New-Object -com "Wscript.Shell"
$sleep = 30


while ($true)
{
  $WShell.sendkeys("{SCROLLLOCK}")
  Start-Sleep -Milliseconds 100
  Write-Host "Press Scroll lock"
  $WShell.sendkeys("{SCROLLLOCK}")
  Write-Host "Waiting " $sleep " seconds" 
  Start-Sleep -Seconds $sleep
}'

# Set running user variable and script path

$user = "CustomerService"
$scriptfile = "C:\Users\$user\ScriptTask.ps1"

# Create Script File

$TaskScript | Out-File $scriptfile

#Create Scheduled Task

$trigger = New-ScheduledTaskTrigger -AtLogOn
$action = New-ScheduledTaskAction -Execute Powershell.exe -Argument "-executionpolicy bypass $scriptfile"

Register-ScheduledTask -User $user -TaskName "ScriptTask" -Trigger $trigger -Action $action

# Start Scheduled Task

Start-ScheduledTask -TaskName "ScriptTask"

Stop-Transcript
