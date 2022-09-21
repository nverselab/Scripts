## Install .AppxBundle and Dependencies 
## NOTE: Add-AppxPackage must be run in User Context. If you want to install for all users as System, you'll need to use 'DISM.exe /Online /Add-ProvisionedAppxPackage /PackagePath:$AppxBundle /SkipLicense' and call out each dependency individually with /DependencyPackagePath.

$AppxBundle= Get-ChildItem -Path "$PSScriptRoot" -Filter "*.AppxBundle*" | Select-Object -ExpandProperty FullName # Searches the directory where the script was run for .AppxBundle files
$Dependencies = Get-ChildItem -Path "$PSScriptRoot\dependencies" -Filter "*.appx*" | Select-Object -ExpandProperty FullName # Include dependency .appx files in a subdirectory labeled "dependencies".  If none needed, remove this line and the -DependencyPath flag from Add-AppxPackage

Add-AppxPackage -Path "$AppxBundle" -DependencyPath $Dependencies

## Detection Script

$AppxName="Microsoft.CompanyPortal" # This is the expected AppxPackage Name attribute
$AppxLookup=$(Get-AppxPackage | Where-Object {$_.Name -eq "$AppxName"})

if (Test-Path $AppxLookup.InstallLocation) {

    write-host "$AppxLookup Installed Successfully."
    exit 0

    }

else {

    write-host "The AppxBundle failed to Install."
    exit 1

    }