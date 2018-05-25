Param(
    [string]$version='latest'
)
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$base_url = "https://github.com/Microsoft/K8s-Storage-Plugins/releases"
$filename = "flexvolume-windows.zip"
$versionFile = 'microsoft-windows-plugin-version.txt'
$downloadFolder = 'c:\download'

mkdir $downloadFolder

#get version
if($version -eq 'latest')
{
    $web_request = Invoke-WebRequest "$($base_url)/latest" -Headers @{"Accept"="application/json"}
    $json = $web_request.Content | ConvertFrom-Json
    $version = $json.tag_name
}

#download files
Invoke-WebRequest -uri "$($base_url)/download/$($version)/$filename" -o "$downloadFolder\$filename"
Invoke-WebRequest -uri "$($base_url)/download/$($version)/$($filename).sha256" -o "$($filename).sha256"

#validate hash matches
$sha256 = get-content -path "$($filename).sha256"
$sha256 = $sha256.Split(" ")[0]
$hash = Get-FileHash -Algorithm SHA256 -Path "$downloadFolder\$filename"
if($hash.Hash -ne $sha256)
{
    throw "hashes do not match"
}

$version | out-file -FilePath "$downloadFolder\$versionFile" -encoding ascii
