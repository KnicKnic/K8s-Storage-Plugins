
$ClusterSecrets = @('CLUSTER_USERNAME',
'CLUSTER_PASSWORD' )

function CreateDisk(
    [string] $name,
    [uint64] $requestSize,
    [string] $clustername,
    [string] $clusterusername,
    [string] $clusterpassword,
    [string] $ResiliencySettingName,
    [string] $fsType,
    [string] $storagePoolFriendlyName
)
{
    $s = {
        $name = $Using:name
        $fsType = $Using:fsType
        $storagePoolFriendlyName = $Using:storagePoolFriendlyName
        $requestSize = $Using:requestSize
        $v = ""
        try{
            #get-volume -FileSystemLabel $name -CimSession $session -ErrorAction Stop
            $v = Get-VirtualDisk -FriendlyName $name -ErrorAction Stop   2>&1
            #ensure that there is a volume on the partition
            $exists = $v |  get-disk | %{( $_ | Get-Partition )[1]} | Get-Volume 
            if(-not $exists)
            {
                throw "no volume"
            }
        }catch{
            $options = @{}
            if($ResiliencySettingName)
            {
                $options["-ResiliencySettingName"] = $ResiliencySettingName
            }
            $v = New-Volume -FriendlyName $name -FileSystem $fsType -StoragePoolFriendlyName $storagePoolFriendlyName -size $requestSize @options -ErrorAction SilentlyContinue     2>&1 
        }
        $group =""
        try{            
            $group = get-clustergroup $name   -ErrorAction Stop   2>&1
        }catch{  
            $group = add-clustergroup $name
        }

        $res = get-clusterresource "Cluster Virtual Disk ($name)"
        $out = $res | move-clusterresource -group $group 
    }
    
    
    $password = ConvertTo-SecureString -String $clusterpassword  -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clusterusername, $password 
    invoke-command -ComputerName $clustername  -Credential $cred -ScriptBlock $s
}

function RemoveShare([string]$cluster,[string]$name, [string]$clusterusername, [string]$clusterpassword)
{
    $s = {
        try{

        Get-VirtualDisk -FriendlyName $Using:name -ErrorAction Stop   2>&1 | Remove-VirtualDisk -Confirm:$false -ErrorAction Stop   2>&1 | out-null
        }catch{}
        try{Remove-ClusterGroup $Using:name -Force -RemoveResources  -ErrorAction Stop   2>&1 | out-null }catch{}
    }
    $password = ConvertTo-SecureString -String $clusterpassword  -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clusterusername, $password 
    invoke-command -ComputerName $cluster  -Credential $cred -ScriptBlock $s

}

function supports_s2d($options)
{
    return [bool] $options.parameters.s2dStoragePoolFriendlyName
}

function provision_s2d($options)
{
    $serverName = $options.parameters.s2dServerName 
    $name = $options.name
    $requestSize = ConvertKubeSize $options.volumeClaim.spec.resources.requests.storage
    $storagePoolFriendlyName = $options.parameters.s2dStoragePoolFriendlyName
    $fsType = $options.parameters.s2dFsType
    $ResiliencySettingName =  $options.parameters.s2dResiliencySettingName
 

    $secrets = LoadSecrets -secrets $ClusterSecrets
    CreateDisk -name $name `
                -requestSize $requestSize `
                -clustername $serverName `
                -clusterusername $secrets['CLUSTER_USERNAME'] `
                -clusterpassword $secrets['CLUSTER_PASSWORD'] `
                -ResiliencySettingName $ResiliencySettingName `
                -fsType $fsType `
                -storagePoolFriendlyName $storagePoolFriendlyName 
                        
    $ret = @{"metadata" = @{
                "labels" =@{
                    "proto" = "pdr" } }; 
            "spec"= @{
                "flexVolume" = @{
                    "driver" = "microsoft.com/wsfc-pdr.cmd";
                    "options" = @{
                        "groupName" = $name;
                        "clusterName" = $serverName } } } }
                        
    return $ret
}

function delete_s2d($options)
{

    $secrets = LoadSecrets($ClusterSecrets)
    $clusterName =  $options.volume.spec.flexVolume.options.clusterName
    
    RemoveShare `
        -cluster $clusterName `
        -name $options.volume.metadata.name `
        -clusterusername $secrets['CLUSTER_USERNAME'] `
        -clusterpassword $secrets['CLUSTER_PASSWORD'] 
}