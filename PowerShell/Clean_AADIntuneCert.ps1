# CDJ/AAD Values Clean-Up
# Set variables to indicate value and key to set
$RegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\CDJ\AAD'
$expectedTenantId = "YOUR_EXPECTED_TENANT_ID"
$expectedTenantName = "YOUR_EXPECTED_TENANT_NAME"

# Log file path
$logFilePath = "C:\AAD_IntuneCertKeyRemoval.log"

# Create the log file path if it does not exist.
$folderPath = Split-Path $logFilePath -Parent
if (-not (Test-Path $folderPath)) {
  New-Item -Path $folderPath -ItemType Directory
}

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $message | Out-File -Append -FilePath $logFilePath -NoClobber
}

# Check for old SCP in Registry
If (Test-Path $RegistryPath) {
    $currentTenantId = Get-ItemProperty -Path $registryPath | Select-Object -ExpandProperty TenantId
    $currentTenantName = Get-ItemProperty -Path $registryPath | Select-Object -ExpandProperty TenantName

    if ($currentTenantId -eq $expectedTenantId -and $currentTenantName -eq $expectedTenantName) {
        # Registry values match the expected values, proceed with dsregcmd commands
        Write-Host "Registry values match. Leaving and joining AAD..."
        Start-Process -FilePath "dsregcmd" -ArgumentList "/leave" -Wait
        Start-Process -FilePath "dsregcmd" -ArgumentList "/join" -Wait
        Log-Message "Registry values match the expected values, proceed with dsregcmd commands."
    }
    else {
        # Registry values do not match the expected values, remove the registry path and set expected values
        Write-Host "Registry values do not match the expected values. Removing registry path and setting expected values..."
        Remove-Item -Path $registryPath -Force
        New-Item -Path $registryPath -Force
        New-ItemProperty -Path $registryPath -Name "TenantId" -Value $expectedTenantId -Force
        New-ItemProperty -Path $registryPath -Name "TenantName" -Value $expectedTenantName -Force
        Log-Message "Registry values do not match the expected values. Removing registry path and setting expected values and proceeding with dsregcmd commands..."
        Start-Process -FilePath "dsregcmd" -ArgumentList "/leave" -Wait
        Start-Process -FilePath "dsregcmd" -ArgumentList "/join" -Wait
    }
}
else {
    # Registry key not found, set expected values
    Write-Host "Registry key not found. Setting expected values..."
    New-Item -Path $registryPath -Force
    New-ItemProperty -Path $registryPath -Name "TenantId" -Value $expectedTenantId -Force
    New-ItemProperty -Path $registryPath -Name "TenantName" -Value $expectedTenantName -Force
    Log-Message "Registry keys not found. Setting expected values and proceeding with dsregcmd commands..."
    Start-Process -FilePath "dsregcmd" -ArgumentList "/leave" -Wait
    Start-Process -FilePath "dsregcmd" -ArgumentList "/join" -Wait
}

# Clean up Intune

if (!(Test-Path $logFilePath)) {
    # Check if log file already exists
    $IntuneCleanUpLogExists = Test-Path "C:\Windows\Temp\CertKeyRemoval.log"
    if (!$IntuneCleanUpLogExists) {

    $IntuneCert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Issuer -like '*Microsoft Intune*' }
    If($IntuneCert){
        $IntuneCert | Remove-Item -Confirm:$false -Force
        Log-Message "Intune certificate removed."
    }
    Else{
        $CertError = "Could not find and delete Intune cert."
        $CertError | Out-File C:\Windows\Temp\CertKeyRemoval.log -Append -NoClobber
        Log-Message $CertError
    }

        $IntuneGUIDs = Get-ChildItem C:\ProgramData\Microsoft\DMClient\
        If($IntuneGUIDS){
            ForEach($GUID in $IntuneGUIDs){
                $Key=$GUID.Name
                Get-Item HKLM:\SOFTWARE\Microsoft\Enrollments\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\Enrollments\Status\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\PolicyManager\AdmxInstalled\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Logger\$Key | Remove-Item -Force -Verbose -Recurse
                Get-Item HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Sessions\$Key | Remove-Item -Force -Verbose -Recurse
                Log-Message "Intune cleanup completed."
            }
        }
    }
    else {
        Log-Message "Intune cleanup log already exists. Skipping cleanup."
    }
} 
Else{
    Log-Message "No GUIDS found for use in delting keys. Check C:\ProgramData\Microsoft\DMClient\"
}

# Run dsregcmd /status and capture the output
$dsregcmdOutput = dsregcmd /status

# Check if either expectedTenantId or expectedTenantName is present in the output
if ($dsregcmdOutput -match $expectedTenantId -or $output -match $expectedTenantName) {
    Log-Message "Expected tenant values were found in dsregcmd /status output."
} else {
    # Display the whole output if neither expectedTenantId nor expectedTenantName is present
    Log-Message "Expected tenant values were NOT found in dsregcmd /status output."
    Log-Message $dsregcmdOutput
}

# Log errors
$Error | ForEach-Object { $_.ToString() } | Out-File -Append -FilePath $logFilePath -NoClobber
$Error.Clear()
