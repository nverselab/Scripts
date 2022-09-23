$Reader32 = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
$Reader64 = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"

If((Test-Path $Reader32) -or (Test-Path $Reader64)) {
    
    Write-Host "Acrobat Reader DC Found.  Exiting Successfully."
    exit 0

}

Else {

    Write-Host "Acrobat Reader DC not found.  Exiting Unsuccessfully."
    exit 1 

}