$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$versionFile = "microsoft-windows-plugin-version.txt"
$pluginDest = "c:\dest"
$pluginSrc = "c:\src"

#check Version on share
#and exit with zero if do not need update
try{
    $contentDest = get-content -Path "$pluginDest\$versionFile" -encoding ascii | Select-Object -first 1
    $contentSrc = get-content -Path "$versionFile" -encoding ascii | Select-Object -first 1
    
    if($contentSrc.trim() -eq $contentDest.trim()){
        exit 0
    }
}
catch{
    #we had trouble parsing the version number, just eat it
    #and overwrite the existing files
}
copy -recurse -Path "$pluginSrc\plugins\*" -Destination $pluginDest -Force
# copy "$versionFile" "$pluginDest\$versionFile" -Force