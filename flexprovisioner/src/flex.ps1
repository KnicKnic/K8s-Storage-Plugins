$global:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

. $PSScriptRoot\flexvolume.ps1
. $PSScriptRoot\iscsi.ps1
. $PSScriptRoot\smb.ps1
. $PSScriptRoot\s2d.ps1

function init()
{
}

function delete_command($options)
{      
    DebugLog  "Delete $options"
    if($options.volume.spec.flexVolume.driver -eq "microsoft.com/iscsi.cmd")
    {
        return delete_iscsi $options
    }
    else 
    {
        if($options.volume.spec.flexVolume.options.s2dShareServer)
        {
            return delete_s2d $options        
        }
        else
        {
            return delete_smb $options           
        }
    }
}

function provision_command($options)
{  
    DebugLog  "Provision $options"

    $noReadWriteMany = -not $options.volumeClaim.spec.accessModes.Contains("ReadWriteMany")
    if($noReadWriteMany -and $(supports_iscsi $options))
    {
        return provision_iscsi $options
    }
    elseif (supports_s2d $options)
    {
        return provision_s2d $options        
    }
    elseif (supports_smb $options)
    {
        return provision_smb $options        
    }
    else
    {
        if(-not $noReadWriteMany)
        {
            throw "Could not find an appropriate provisioner, cannot create ReadWriteMany for iSCSI and SMB is not supported "
        }
        else
        {
            throw "Could not find an appropriate provisioner, please set parameters for iSCSI or SMB "   
        }
    }
}

RunFlexVolume
DebugLog "ran flexvolume"