# CDJ/AAD Values Clean-Up
# Set variables to indicate value and key to set
$RegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\CDJ\AAD'
$expectedTenantId = "YOUR_EXPECTED_TENANT_ID"
$expectedTenantName = "YOUR_EXPECTED_TENANT_NAME"

# Log file path
$logFilePath = "C:\AAD_IntuneCertKeyRemoval.log"

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
    }
    else {
        # Registry values do not match the expected values, remove the registry path and set expected values
        Write-Host "Registry values do not match the expected values. Removing registry path and setting expected values..."
        Remove-Item -Path $registryPath -Force
        New-Item -Path $registryPath -Force
        New-ItemProperty -Path $registryPath -Name "TenantId" -Value $expectedTenantId -Force
        New-ItemProperty -Path $registryPath -Name "TenantName" -Value $expectedTenantName -Force
    }
}
else {
    # Registry key not found, set expected values
    Write-Host "Registry key not found. Setting expected values..."
    New-Item -Path $registryPath -Force
    New-ItemProperty -Path $registryPath -Name "TenantId" -Value $expectedTenantId -Force
    New-ItemProperty -Path $registryPath -Name "TenantName" -Value $expectedTenantName -Force
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
    $GUIDSError = "No GUIDS found for use in delting keys. Check C:\ProgramData\Microsoft\DMClient\"
    $GUIDSError | Out-File C:\Windows\Temp\CertKeyRemoval.log -Append -NoClobber
}

# Log errors
$Error | ForEach-Object { $_.ToString() } | Out-File -Append -FilePath $logFilePath -NoClobber
$Error.Clear()
