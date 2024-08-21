# Define the URL for Sysmon download
$sysmonUrl = "https://live.sysinternals.com/Sysmon64.exe"

# Define the destination folder
$destinationFolder = "C:\ProgramData\Sysmon"

# Create the destination folder if it does not exist
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Define the destination path for Sysmon64.exe
$destinationPath = Join-Path -Path $destinationFolder -ChildPath "Sysmon64.exe"

# Download Sysmon64.exe
Invoke-WebRequest -Uri $sysmonUrl -OutFile $destinationPath

# Run Sysmon64.exe with -i and -accepteula arguments
Start-Process -FilePath $destinationPath -ArgumentList "-i", "-accepteula" -Wait
