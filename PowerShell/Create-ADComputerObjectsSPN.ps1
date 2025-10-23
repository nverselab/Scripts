# Define the OU path
$OU = "OU=macs,OU=workstations,DC=domain,DC=local"
 
# Path to the input file containing computer names (one per line)
$InputFile = "C:\Path\To\computer_names.txt"
 
# Import Active Directory module
Import-Module ActiveDirectory
 
# Read computer names from the file
$ComputerNames = Get-Content -Path $InputFile
 
foreach ($ComputerName in $ComputerNames) {
    $FQDN = "$ComputerName.domain.local"
    $SPN = "HOST/$FQDN"
 
    # Create the computer account
    New-ADComputer -Name $ComputerName -SamAccountName "$ComputerName$" -Path $OU -Enabled $true
 
    # Set the SPN
    Set-ADComputer -Identity $ComputerName -ServicePrincipalNames @{Add=$SPN}
 
    Write-Host "Created '$ComputerName' in '$OU' with SPN '$SPN'"
}
