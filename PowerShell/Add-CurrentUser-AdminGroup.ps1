# Check if running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an administrator."
    Exit
}

# Get the currently logged-in user without prompt
$currentUserName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").LastLoggedOnUser -replace '@.*$'
$currentUserName = $currentUserName -replace '^.*\\'

# Check if the user is already a member of the Administrators group
if (Get-LocalGroupMember -Group "Administrators" -Member $currentUserName -ErrorAction SilentlyContinue) {
    Write-Host "User $currentUserName is already a member of the Administrators group."
} else {
    # Add the user to the Administrators group
    Add-LocalGroupMember -Group "Administrators" -Member $currentUserName
    Write-Host "User $currentUserName has been added to the Administrators group."
}
