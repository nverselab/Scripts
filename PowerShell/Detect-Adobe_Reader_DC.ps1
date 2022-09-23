$Reader32 = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
$Reader64 = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"

If(Test-Path $Reader32) {
    
    Write-Host "Reader 32 bit found.  Exiting Successfully."
    exit 0

}

Else {

    If (Test-Path $Reader64) {

    Write-Host "Reader 64 bit found. Exiting Successfully."
    exit 0

    }

    Else { 
        
        Write-Host "Reader DC not found.  Exiting Unsuccessfully."
        exit 1 
        
        }

}