$AppxName="Microsoft.CompanyPortal" # This is the expected AppxPackage Name attribute
$AppxBundle= Get-ChildItem -Path "$PSScriptRoot" -Filter "*.AppxBundle*" | Select-Object -ExpandProperty FullName # Searches the directory where the script was run for .AppxBundle files
$Dependencies = Get-ChildItem -Path "$PSScriptRoot\dependencies" -Filter "*.appx*" | Select-Object -ExpandProperty FullName # Include dependency .appx files in a subdirectory labeled "dependencies".  If none needed, remove this line and the -DependencyPath flag from Add-AppxPackage

Add-AppxPackage -Path "$AppxBundle" -DependencyPath $Dependencies

$AppxLookup=$(Get-AppxPackage | Where-Object {$_.Name -eq "$AppxName"})

## Detection Script

if (Test-Path $AppxLookup.InstallLocation) {

    write-host "$AppxLookup Installed Successfully."
    $True
    exit 0

    }

else {

    write-host "The AppxBundle failed to Install."
    $False
    exit 1

    }