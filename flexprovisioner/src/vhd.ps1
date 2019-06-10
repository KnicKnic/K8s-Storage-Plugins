function supports_vhd($options)
{
    return [bool] $options.parameters.vhdProvision
}

# Takes in \\servername\share\path or smb://servername/share/path or //servername/share/path
# and returns \\servername\share\path
function MigrateLinuxCifsPathToWindows([string]$smbPath)
{
    if($smbPath.StartsWith('smb://','CurrentCultureIgnoreCase'))
    {
        $smbPath = '//' + $smbPath.SubString('smb://'.Length)
    }
    if($smbPath.StartsWith('//'))
    {
        $smbPath = $smbPath.replace('/', '\')
    }
    return $smbPath
}

function GetServerNameOrParseSharename([string] $serverName, [string]$shareName)
{
    if($serverName)
    {
        return $serverName
    }
    # returns from format take '\\<server>\'
    return $shareName.split('\')[2]
}

function GetShareRootLocalPath([string]$ComputerName, $shareName, $credential = $null)
{
    $cimSession = ConstructCimsession -ComputerName $ComputerName -credential $credential
    $share = Get-SmbShare -Name $shareName -CimSession $cimSession
    return $share.Path
}
function SharePathHasFolder($path)
{
    return [bool]( Split-path -Path $path -parent )
}
function GetRootSharePath($path)
{
    while(SharePathHasFolder -Path $path)
    {
        $path = Split-path -Path $path -parent
    }
    return $path
}

function GetLocalSharePath($serverName, $remotePath, $credential)
{
    $rootSharePath = GetRootSharePath -path $remotePath
    $shareName = $rootSharePath.split('\')[3]
    $rootLocalPath = GetShareRootLocalPath $serverName $shareName $credential
    $localPath = $rootLocalPath
    if(SharePathHasFolder -path $remotePath)
    {
        #eat (\\servername\share\)subfolder1\..\
        $additionalPath = $remotePath.SubString($rootSharePath.Length + 1)

        $localPath = JoinPathNoCheck $localPath $additionalPath
    }
    return $localPath
}

function provision_vhd($options)
{
    $name = $options.name
    $vhdName = $name + ".vhdx"
    $remotePath = MigrateLinuxCifsPathToWindows -smbPath $options.parameters.smbShareName
    $serverName = GetServerNameOrParseSharename -serverName $options.parameters.smbServerName -shareName $remotePath
    $secret = $options.parameters.smbSecret
    $credential = GetCredential

    $localPath = $options.parameters.smbLocalPath
    if(-not $localPath)
    {
        $localPath = GetLocalSharePath $serverName $remotePath $credential
    }
    
    $path = JoinPathNoCheck $remotePath $vhdName
    $localPath = JoinPathNoCheck $localPath $vhdName
    $requestSize = ConvertKubeSize $options.volumeClaim.spec.resources.requests.storage

    DebugLog "Remote path $remotePath"
    DebugLog "Local path $localPath"
    
    DebugLog "Requestsize $requestSize"

    # don't actually create the vhd...
    # doing this because it is easier to create on host which has access to runhcs
    # this should happen here, and the VHD should be correctly size bounded
                        
    $ret = @{"metadata" = @{
                "labels" =@{
                    "proto" = "vhd" } }; 
            "spec"= @{
                "flexVolume" = @{
                    "driver" = "microsoft.com/vhd.cmd"; 
                    "secretRef" = @{
                        "name" = $secret };
                    "options" = @{
                        "source" = $path;
                        "vhdProvision" = "true";
                        "localPath" = $localPath;
                        "serverName"= $serverName; } } } }
                        
    return $ret
}

function delete_vhd($options)
{
    $credential = GetCredential
    $serverName = $options.volume.spec.flexVolume.options.serverName
    DeleteRemoteFile $options.volume.spec.flexVolume.options.localPath -ComputerName $serverName -credential $credential
}