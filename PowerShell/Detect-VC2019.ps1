[array]$AppName = "Microsoft Visual C++ 2015-2019", "Microsoft Visual C++ 2015-2022"
[version]$RequiredVersion = "14.29.30133"
[string]$Architecture = "x64"

[array]$Hives = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\",
                "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"

$Hives | ForEach-Object {
    Get-ChildItem -Path $_ | ForEach-Object {
        $Properties = $_ | Get-ItemProperty
        if(
            $Properties.DisplayName -and
            $Properties.DisplayName.Contains("$("($Architecture)")") -and
            (
                $AppName | Where-Object {
                    $Properties.DisplayName.StartsWith($_)
                }
            )
        ){
            $CurrentVersion = [version]$Properties.DisplayVersion
            if($CurrentVersion -ge $RequiredVersion){
                "installed"
            }
        }
    }
}
