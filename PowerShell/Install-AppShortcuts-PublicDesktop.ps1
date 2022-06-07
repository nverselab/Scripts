function set-shortcut {
    param ( [string]$SourceLnk, [string]$DestinationPath )
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($SourceLnk)
        $Shortcut.TargetPath = $DestinationPath
        $Shortcut.Save()
        }
    
    $DesktopPath = ([Environment]::GetEnvironmentVariable("Public")) + "\Desktop"
    
    $ShortcutPath = "C:\Program Files\Microsoft Office\root\Office16"
    
    $ShortcutTarget = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE",
    "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE",
    "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
    
    if(Test-Path -path $ShortcutPath){
    
        write-host "Shortcut already exists.  Skipping."
    
        }
    
        Else {
    
        set-shortcut $ShortcutPath $ShortcutTarget
    
        If (Test-Path -path $ShortcutPath){
    
            write-host "Shortcut successfully created."
    
            }
    
            Else {
            
                write-host "Shortcut creation failed."
                exit 1
    
                }
    
        }