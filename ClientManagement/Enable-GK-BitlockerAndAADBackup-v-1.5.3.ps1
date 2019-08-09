#region initialise

# set script name
# $scriptname = $MyInvocation.MyCommand.Name
$scriptname = "Enable-GK-BitlockerAndAADBackup"

# initialize logging
$logroot = "C:\Windows\Logs\RealmJoin\Packages"
$logdate = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logfolder= -join ($logroot, "\", $scriptname)
$logfile = -join ($logfolder, "\", $logdate, "_", $scriptname, ".log")

# test if log path already available
if(!(Test-Path $logfolder))
{
    # create log directory
    New-Item -Path $logroot -Name $scriptname -ItemType Directory
}

# start logging
Start-Transcript -Path $logfile -Force

# script Infos

Write-Host "--------------------------------------------------------------------------------------"
Write-Host  "title: enable bitlocker and backup to AAD"
Write-Host  "created: 08/02/2019"
Write-Host  "by: Gerrit Reinke (Glueck & Kanja)"
Write-Host  "version: 1.5.3"
Write-Host "--------------------------------------------------------------------------------------"

# set script vars

[string]$OSDrive = "C:"
[string]$EncryptionMethod = "XtsAes256" # 	supported Aes128, Aes256, XtsAes128, XtsAes256

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#endregion

#region EnableBitlocker

try
{
       
    # Running as SYSTEM BitLocker may not implicitly load and running as SYSTEM the env variable is likely not set, so explicitly load it
    Import-Module -Name C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\BitLocker -Verbose

    # --------------------------------------------------------------------------
    #  Let's dump the starting point
    # --------------------------------------------------------------------------
    Write-Host "--------------------------------------------------------------------------------------"
    Write-Host " STARTING POINT:  Get-BitLockerVolume " + $OSDrive
    Write-Host "--------------------------------------------------------------------------------------"
    $bdeStartingStatus = Get-BitLockerVolume $OSDrive 


    #  Evaluate the Volume Status to see what we need to do...
    $bdeProtect = Get-BitLockerVolume $OSDrive | select -Property VolumeStatus, KeyProtector
    # Account for an uncrypted drive 
    if (($bdeProtect.VolumeStatus -eq "FullyDecrypted") -or ($bdeProtect.KeyProtector.Count -lt 1)) 
    {
        Write-Host "--------------------------------------------------------------------------------------"
        Write-Host " Enabling BitLocker due to FullyDecrypted status or KeyProtector count less than 1"
        Write-Host "--------------------------------------------------------------------------------------"
        # Enable Bitlocker using TPM
        Enable-BitLocker -MountPoint $OSDrive -EncryptionMethod $EncryptionMethod -TpmProtector -SkipHardwareTest -UsedSpaceOnly -ErrorAction Continue
        Enable-BitLocker -MountPoint $OSDrive -EncryptionMethod $EncryptionMethod -RecoveryPasswordProtector -SkipHardwareTest -WarningAction SilentlyContinue
    }  
    elseif(($bdeProtect.VolumeStatus -eq "FullyEncrypted") -or ($bdeProtect.VolumeStatus -eq "UsedSpaceOnly")) 
    {
        # $bdeProtect.ProtectionStatus -eq "Off" - This catches the Wait State
        if($bdeProtect.KeyProtector.Count -lt 2)
        {
            Write-Host "--------------------------------------------------------------------------------------"
            Write-Host " Volume Status is encrypted, but BitLocker only has one key protector (TPM)"
            Write-Host "  Adding a RecoveryPasswordProtector"
            Write-Host "--------------------------------------------------------------------------------------"
            manage-bde -on $OSDrive -UsedSpaceOnly -rp
        }
        else
        {
            Write-Host "--------------------------------------------------------------------------------------"
            Write-Host " BitLocker is in Wait State - running manage-bde -on -UsedSpaceOnly"
            Write-Host "--------------------------------------------------------------------------------------"
            manage-bde -on $OSDrive -UsedSpaceOnly
        }
    }    

    #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
    $cmdName = "BackupToAAD-BitLockerKeyProtector"
    if(Get-Command $cmdName -ErrorAction SilentlyContinue)
    {
        Write-Host "--------------------------------------------------------------------------------------"
        Write-Host " Saving Key to AAD using BackupToAAD-BitLockerKeyProtector commandlet"
        Write-Host "--------------------------------------------------------------------------------------"
        #BackupToAAD-BitLockerKeyProtector commandlet exists
        $BLV = Get-BitLockerVolume -MountPoint $OSDrive | select *
        BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
    }
    else
    { 
        # BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanisme  
        # Get the AAD Machine Certificate
        $cert = dir Cert:\LocalMachine\My\ | where { $_.Issuer -match "CN=MS-Organization-Access" }

        # Obtain the AAD Device ID from the certificate
        $id = $cert.Subject.Replace("CN=","")

        # Get the tenant name from the registry
        $tenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id)).UserEmail.Split('@')[1]

        # Generate the body to send to AAD containing the recovery information
        Write-Host "--------------------------------------------------------------------------------------"
        Write-Host " COMMAND BackupToAAD-BitLockerKeyProtector failed!"
        Write-Host " Saving key protector to AAD for self-service recovery by manually posting it to:"
        Write-Host "                     https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
        Write-Host "--------------------------------------------------------------------------------------"
        # Get the BitLocker key information from WMI
        (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector|?{$_.KeyProtectorType -eq 'RecoveryPassword'} | %{
            $key = $_
            write-verbose "kid : $($key.KeyProtectorId) key: $($key.RecoveryPassword)"
            $body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}"

            # Create the URL to post the data to based on the tenant and device information
            $url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"

            # Post the data to the URL and sign it with the AAD Machine Certificate
            $req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert
            $req.RawContent
            Write-Host "--------------------------------------------------------------------------------------"
            Write-Host " -- Key save web request sent to AAD - Self-Service Recovery should work"
            Write-Host "--------------------------------------------------------------------------------------"
        }
    }

    #In case we had to encrypt, turn it on for any enabled volume
    Get-BitLockerVolume | Resume-BitLocker

    # --------------------------------------------------------------------------
    #  Finish - Let's dump the ending point
    # --------------------------------------------------------------------------
    Write-Host "--------------------------------------------------------------------------------------"
    Write-Host " ENDING POINT:  Get-BitLockerVolume $OSDrive"
    Write-Host "--------------------------------------------------------------------------------------"
    $bdeProtect = Get-BitLockerVolume $OSDrive 

    #>
} 
catch 
{ 
    write-error "Error while setting up AAD Bitlocker, make sure that you are AAD joined and are running the cmdlet as an admin: $_" 
}

#endregion

#region end

Write-Host "Script Finished, Exit"

Stop-Transcript
Exit

#endregion