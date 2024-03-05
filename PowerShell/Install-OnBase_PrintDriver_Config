# Variables
$OnBaseInstaller = "HylandUnityClient.msi"
$PrintDriverInstaller = "HylandOnBaseVirtualPrintDriverx64.msi"
$OnBaseConfig = "obunity.exe.config"
$OnBaseConfigPath = "C:\Program Files (x86)\Hyland\Unity Client\obunity.exe.config"

# Start Install
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$OnBaseInstaller`" /quiet" -Wait
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$PrintDriverInstaller`" /quiet" -Wait

# Overwrite Config File
Copy-Item -Path $OnBaseConfig -Destination $OnBaseConfigPath -Force
