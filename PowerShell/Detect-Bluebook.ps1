# Get the currently logged-in user's username including domain
$currentUserWithDomain = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Extract the username from the fully qualified username (domain\username)
$currentUser = $currentUserWithDomain.Split('\')[1]

# Define the path to the bluebook.exe file for the current user
$bluebookPath = "C:\Users\$currentUser\AppData\Local\Programs\bluebook\bluebook.exe"

# Check if bluebook.exe exists
if (Test-Path -Path $bluebookPath -PathType Leaf) {
    Write-Host "bluebook.exe found in $bluebookPath"
    exit 0
} else {
    Write-Host "bluebook.exe not found in $bluebookPath"
    exit 1
}
