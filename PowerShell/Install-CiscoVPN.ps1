# Define the source and destination paths
$sourcePath = ".\VPN-Profile.xml"
$destinationPath = "C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile\TKG-VPN-Profile-v1.xml"
$installerPath = ".\cisco-secure-client-win-5.1.8.105-core-vpn-predeploy-k9.msi"

# Check if the source file exists
if (Test-Path $sourcePath) {
    # Create the destination directory if it does not exist
    $destinationDir = [System.IO.Path]::GetDirectoryName($destinationPath)
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force
    }

    # Copy the XML file to the destination
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force

    # Check if the installer file exists
    if (Test-Path $installerPath) {
        # Run the installer
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait
        Write-Output "Installer executed successfully."
    } else {
        Write-Output "Installer file not found: $installerPath"
    }
} else {
    Write-Output "Source file not found: $sourcePath"
}
Collapse
has context menu
