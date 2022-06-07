$applicaion = "*Adobe*"

$searchobjects = get-wmiobject Win32_Product | Where-Object {$_.Name -like $application}

foreach ($a in $searchobjects) {

Write-host "Found $a.Name ... Removing $a.IdentifyingNumber"

Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/x $($a.IdentifyingNumber) /qn" -Wait

}