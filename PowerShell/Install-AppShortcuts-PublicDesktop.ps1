$Array = @(
    @{Target="C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE";ShortcutPath="$env:Public\Desktop\Word.lnk"},
    @{Target="C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE";ShortcutPath="$env:Public\Desktop\Excel.lnk"},
    @{Target="C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE";ShortcutPath="$env:Public\Desktop\Outlook.lnk"}) | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }


$Array.count

for($i=0; $i -lt $Array.count; $i++){

$TargetFile = $Array[$i].Target
$ShortcutPath = $Array[$i].ShortcutPath

Write-Host "Creating $TargetFile for $ShortcutPath"

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

 }