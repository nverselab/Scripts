$arguments = '/I googlechromestandaloneenterprise64v99.msi /qn /norestart'

Start-Process msiexec.exe -ArgumentList $arguments -Wait

if (Test-Path "c:\Program Files\Google\Chrome\Application") {

    Copy-Item "master_preferences" "c:\Program Files\Google\Chrome\Application" -Force -ErrorAction Ignore

}

if (Test-Path "c:\Program Files (x86)\Google\Chrome\Application") {

    Copy-Item "master_preference" "C:\Program Files (x86)\Google\Chrome\" -Force -ErrorAction Ignore

}

exit 0