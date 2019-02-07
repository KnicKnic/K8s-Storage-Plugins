function NewFsrmQuota($path, [uint64]$size, $ComputerName)
{
#$empty = New-FsrmQuota -Path $fsrmPath -Size $requestSize -CimSession $ComputerName -ErrorAction Stop 2>&1   
# 
# using wmi instead due to cmdlets not being installable on server_core
# also reduces dependencies
$empty = New-CimInstance -ClassName "MSFT_FSRMQuota" -Namespace "Root/Microsoft/Windows/FSRM" -ComputerName $computername  -Property @{"Path" = $path; "Size" = $size} -erroraction stop  2>&1
}

function SetFsrmQuota($path, [uint64]$size, $ComputerName)
{
#$empty = Set-FsrmQuota -Path $fsrmPath -Size $requestSize -CimSession $serverName -ErrorAction Stop 2>&1
 
# using wmi instead due to cmdlets not being installable on desktop
# using post filtering because of WQL escaping rules
$cimInstance = Get-CimInstance  -ClassName "MSFT_FSRMQuota" -Namespace "Root/Microsoft/Windows/FSRM" -ComputerName $computername -erroraction stop  2>&1 | ?{$_.Path -eq $path} | GetFirst -message "Failed to get instance of MSFT_FSRMQuota"
$cimInstance | Set-CimInstance -ComputerName $computerName -Property @{"Size" = $size} -erroraction stop  2>&1
}

function supports_smb($options)
{
    return [bool] $options.parameters.smbLocalPath
}

function provision_smb($options)
{
    $name = $options.name
    $remotePath = $options.parameters.smbShareName
    $localPath = $options.parameters.smbLocalPath
    $serverName = $options.parameters.smbServerName
    $secret = $options.parameters.smbSecret
    
    $path = $remotePath + '\' + $name
    $localPath = $localPath + '\' + $name
    $requestSize = ConvertKubeSize $options.volumeClaim.spec.resources.requests.storage

    DebugLog "Remote path $remotePath"
    DebugLog "Local path $localPath"

    
    DebugLog "Requestsize $requestSize"
    #new-vhdx
    $vhd =  $remotePath + '\' + $name + '.vhdx'
    
    $pathExists = test-path $vhd
    if(-not $pathExists)
    {
        $a = runhcs.exe create-scratch --destpath $vhd 2>&1 
	DebugLog $a
    }

    DebugLog "made directory"
                        
    $ret = @{"metadata" = @{
                "labels" =@{
                    "proto" = "smb" } }; 
            "spec"= @{
                "flexVolume" = @{
                    "driver" = "microsoft.com/smb.cmd"; 
                    "options" = @{
                        "source" = $vhd;
                        "localPath" = $localPath;
                        "serverName"= $serverName; } } } }
                        
    return $ret
}

function delete_smb($options)
{   
     $vhd = $options.volume.spec.flexVolume.options.source
    $pathExists = test-path $vhd
    if($pathExists )
    {
    	#del  $vhd
    }
}