<#
.SYNOPSIS

.DESCRIPTION

.NOTES
    Company     : Glück & Kanja
    Creation    : 08/02/2019
    Author      : glwr
    Requires    : PowerShell Core 6

.LINK

.EXAMPLE

#># SYNOPSIS
#############################################################################################
#region Param Block
    param
    (
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
        [string]$OSDrive = "C:",
        [Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)]
        [string]$EncryptionMethod = "XtsAes256", # 	supported Aes128, Aes256, XtsAes128, XtsAes256
        [Parameter(Mandatory=$false,Position=2,ValueFromPipeline=$true)]
        [boolean]$RemoveOldEncryption = $true,
        [Parameter(Mandatory=$false,Position=3,ValueFromPipeline=$true)]
        [string]$OldEncryptionMethod  = "*128*", # with this you can disable all 128 bit encryption methods or you can specify a dedicated one
        [Parameter(Mandatory=$false,Position=4,ValueFromPipeline=$true)]
        [boolean]$CheckTPM = $true
    )
#endregion
#############################################################################################
#region ProgramInfo

[string]$Script:ProgramName = "Enable-GK-BitlockerAndAADBackup"
[Version]$Script:ProgramVersion = "1.5.8"
[boolean]$Debug = $false
[boolean]$Verbose = $false
[boolean]$Warning = $false

#endregion
#############################################################################################
#region Pre Steps

    $StartPreStepsDate = Get-Date

    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region initialize logging

        # check if warning messages should be printed or silently continued
        if($Warning){$WarningPreference = "Continue"}else{$WarningPreference = "SilentlyContinue"}
        # check if verbose messages should be printed or silently continued
        if($Verbose){$VerbosePreference = "Continue"}else{$VerbosePreference = "SilentlyContinue"}
        # check if debug, verbose and warning messages should be printed or silently continued
        if($Debug){$DebugPreference = "Continue";$VerbosePreference = "Continue";$WarningPreference = "Continue"}else{$DebugPreference = "SilentlyContinue"}
        
        # define log root folder # if realmjoin is available set to "C:\Windows\Logs\RealmJoin\Packages"
        $LogRoot = "C:\Windows\Logs\RealmJoin\Packages"
        # time stamp for log file name
        $LogDate = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
        # sub folder where logs will be saved
        $LogFolder= -join ($LogRoot, "\", $ProgramName)
        # full path of the log file
        $LogFile = -join ($LogFolder, "\", $LogDate, "_", $ProgramName, ".log")
        
        # test if log path already available
            if(!(Test-Path $LogFolder))
            {
                # create log directory
                New-Item -Path $LogRoot -Name $ProgramName -ItemType Directory
            }

        # start logging
            Start-Transcript -Path $LogFile -Force

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region Function Area
        # if you have some functions, declare them in this region
        
        function Write-TimeDebug
        {
            <#
            .Synopsis
            Writes Debug Message with Timestamp.

            .Description
            Combines Debug Message with current Time.

            .Parameter Message
            Mandatory Text to write as a Debug Message.
            #>

            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
                $Message
            )

            # initialize variables with null
            $Date = $null
            $Output = $null

            # set variables
            $Date = Get-Date -Format "dd-MM-yyyy HH-mm-ss"
            $Output = -join($Date," : ",$Message)

            # write debug message
            Write-Debug "$($Output)"
        }

        function Write-TimeHost
        {
            <#
            .SYNOPSIS 
            Adds Time to Write-Host

            .PARAMETER Message
            Message of Write-Host

            .PARAMETER ForegroundColor
            Desired Output Foreground Color.

            .EXAMPLE
            Write-TimeHost "This is a test"

            .EXAMPLE
            Write-TimeHost "This is a test" -ForegroundColor DarkCyan -NoNewline # if you use -NoNewline use as next output cmdlet Write-Host
            #>

            [CMDletBinding()]
            param
            (
                [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
                [string]$Message,
                [Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)]
                [ValidateSet("Black","Blue","Cyan","Yellow","Magenta","Green","Red","White","Gray","DarkMagenta","DarkRed","DarkGreen","DarkCyan","DarkBlue","DarkGray")]
                [string]$ForegroundColor,
                [Parameter(Mandatory=$false,Position=2,ValueFromPipeline=$false)]
                [switch]$NoNewline
            )

            # initialize variables with null
            $Date = $null
            $Output = $null

            # set variables
            $Date = Get-Date -Format "dd-MM-yyyy HH:mm:ss"    
            $Output = -join($Date," : ",$Message)

            $Command = "Write-Host `$Output"

            # crerate expression command
            if($ForegroundColor)
            {
                $Command = -join ($Command + " -ForegroundColor `$ForegroundColor")
                Write-TimeDebug $Command 
            }
            if($NoNewline)
            {
                $Command = -join ($Command + " -NoNewline")
                Write-TimeDebug $Command
            }

            # invoke expression
            Invoke-Expression -Command $Command
        }
                   
        function Invoke-ClosingTasks
        {
            <#
            .Synopsis
            Invoke Closing Task

            .Description
            Sets Exit State to either Finished or Error
            Required cleanup steps can be implemented

            .Parameter Reason
            Valid strings: "finished", "error"

            #>
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
                [ValidateSet("finished","error")]
                [string]$Reason
            )

            Write-TimeDebug "Running closing tasks..."
            Write-TimeHost "Running closing tasks..."

            Stop-Transcript -ErrorAction SilentlyContinue
            
            # if you need to do steps depending of exit reason put it into this statement
            if($Reason -eq "finished")
            {
                Write-TimeDebug "Execution finisehd. Closing Program..."
                Write-TimeHost "Execution finisehd. Closing Program..." -ForegroundColor Green
                Exit 0
            }
            elseif($Reason -eq "error")
            {
                Write-TimeDebug "Execution run on errors and will be closed..."
                Write-TimeHost "Execution run on errors and will be closed..." -ForegroundColor Red
                Exit 1
            }            
        } 

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region script blocks
        # if you have some script blocks, declare them in this region

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region script variables
        # if you have some variables, declare them in this region
        
        # see param block at the top of the script

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12      

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    $EndPreStepsDate = Get-Date
#endregion
#############################################################################################
#region process area
    Write-TimeHost "Process Area"
    Write-Host "#############################################################################################"

    $StartProcessDate = Get-Date
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        try
        {
            Write-Host "--------------------------------------------------------------------------------------"
            Write-TimeHost  "title: $ProgramName"
            Write-TimeHost  "created: 08/02/2019"
            Write-TimeHost  "by: Gerrit Reinke (Glueck & Kanja)"
            Write-TimeHost  "version: $ProgramVersion"
            Write-Host "--------------------------------------------------------------------------------------"

            Write-TimeHost "Loading Module C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\BitLocker as SYSTEM"
            # Running as SYSTEM BitLocker may not implicitly load and running as SYSTEM the env variable is likely not set, so explicitly load it
            Import-Module -Name C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\BitLocker -Verbose
        
            # --------------------------------------------------------------------------
            #  Let's dump the starting point
            # --------------------------------------------------------------------------
            Write-Host "--------------------------------------------------------------------------------------"
            Write-TimeHost " STARTING POINT:  Get-BitLockerVolume  $OSDrive"
            Get-BitLockerVolume $OSDrive 
            Write-Host "--------------------------------------------------------------------------------------"
            
            #  Evaluate the Volume Status to see what we need to do...
            $bdeProtect = Get-BitLockerVolume $OSDrive | Select-Object -Property VolumeStatus, KeyProtector, EncryptionMethod

            # Check if TPM is available
            if($CheckTPM -eq $true)
            {
                $TPMState = Get-TPM
                if($TPMState.TpmPresent -eq $false)
                {
                    
                    Write-Error "Error, no TPM Chip found!" 
                    Write-TimeHost "TPM State:"
                    $TPMState
                    Invoke-ClosingTasks -Reason error
                }
            }

            if($RemoveOldEncryption -eq $true)
            {
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " Removing old encryption method is equals $RemoveOldEncryption"
                Write-Host "--------------------------------------------------------------------------------------"
                # Check for 128 Bit encryption and disable it
                Write-TimeHost " Check if $OldEncryptionMethod encryption is enabled and start decryption..."
                if((($bdeProtect.VolumeStatus -eq "FullyEncrypted") -or ($bdeProtect.VolumeStatus -eq "UsedSpaceOnly")) -and ($bdeProtect.EncryptionMethod -like $OldEncryptionMethod))
                {
                        Write-TimeHost "start decryption..."
                        Disable-BitLocker -MountPoint $OSDrive
                        Start-Sleep -Seconds 5
                        Write-TimeDebug (Get-BitLockerVolume $OSDrive)
                }
                Write-Host "--------------------------------------------------------------------------------------"
            }
            else
            {
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " Removing old encryption method is equals $RemoveOldEncryption, decryption not required."
                Write-Host "--------------------------------------------------------------------------------------"
                
            }

            #  Evaluate the Volume Status to see what we need to do...
            $bdeProtect = Get-BitLockerVolume $OSDrive | Select-Object -Property VolumeStatus, KeyProtector, EncryptionMethod

            if($bdeProtect.VolumeStatus -eq "DecryptionInProgress")
            {
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " Volume decryption is in progress, waiting till decryption finished..."
                Write-Host "--------------------------------------------------------------------------------------"
                do
                {
                    Start-Sleep -Seconds 10
                    Get-BitLockerVolume -MountPoint $OSDrive
                    $BitlockerDecryptionStatus = Get-BitLockerVolume $OSDrive | Select-Object -Property VolumeStatus, EncryptionMethod, EncryptionPercentage
                }
                until($BitlockerDecryptionStatus.VolumeStatus -ne "DecryptionInProgress")
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " Volume decryption finished. Proceed with next steps."
                Write-Host "--------------------------------------------------------------------------------------"
                
            }
            else
            {
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " No decryption is in progress, go to Encryption steps."
                Write-Host "--------------------------------------------------------------------------------------"
                
            }

            #  Evaluate the Volume Status to see what we need to do...
            $bdeProtect = Get-BitLockerVolume $OSDrive | Select-Object -Property VolumeStatus, KeyProtector, EncryptionMethod

            # Account for an uncrypted drive 
            if (($bdeProtect.VolumeStatus -eq "FullyDecrypted") -or ($bdeProtect.KeyProtector.Count -lt 1)) 
            {
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " Enabling BitLocker due to FullyDecrypted status or KeyProtector count less than 1"
                Write-Host "--------------------------------------------------------------------------------------"
                # Enable Bitlocker using TPM
                Enable-BitLocker -MountPoint $OSDrive -EncryptionMethod $EncryptionMethod -TpmProtector -SkipHardwareTest -UsedSpaceOnly -ErrorAction Continue
                Enable-BitLocker -MountPoint $OSDrive -EncryptionMethod $EncryptionMethod -RecoveryPasswordProtector -SkipHardwareTest -UsedSpaceOnly
            }  
            elseif(($bdeProtect.VolumeStatus -eq "FullyEncrypted") -or ($bdeProtect.VolumeStatus -eq "UsedSpaceOnly")) 
            {
                # $bdeProtect.ProtectionStatus -eq "Off" - This catches the Wait State
                if($bdeProtect.KeyProtector.Count -lt 2)
                {
                    Write-Host "--------------------------------------------------------------------------------------"
                    Write-TimeHost " Volume Status is encrypted, but BitLocker only has one key protector (TPM)"
                    Write-TimeHost "  Adding a RecoveryPasswordProtector"
                    Write-Host "--------------------------------------------------------------------------------------"
                    manage-bde -on $OSDrive -UsedSpaceOnly -rp
                }
                else
                {
                    Write-Host "--------------------------------------------------------------------------------------"
                    Write-TimeHost " BitLocker is in Wait State - running manage-bde -on -UsedSpaceOnly"
                    Write-Host "--------------------------------------------------------------------------------------"
                    manage-bde -on $OSDrive -UsedSpaceOnly
                }
            }    
        
            #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
            $cmdName = "BackupToAAD-BitLockerKeyProtector"
            if(Get-Command $cmdName -ErrorAction SilentlyContinue)
            {
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " Saving Key to AAD using BackupToAAD-BitLockerKeyProtector commandlet"
                Write-Host "--------------------------------------------------------------------------------------"
                #BackupToAAD-BitLockerKeyProtector commandlet exists
                $BLV = Get-BitLockerVolume -MountPoint $OSDrive | Select-Object *
                BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
            }
            else
            { 
                # BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanisme  
                # Get the AAD Machine Certificate
                $cert = Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match "CN=MS-Organization-Access" }
        
                # Obtain the AAD Device ID from the certificate
                $id = $cert.Subject.Replace("CN=","")
        
                # Get the tenant name from the registry
                $tenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id)).UserEmail.Split('@')[1]
        
                # Generate the body to send to AAD containing the recovery information
                Write-Host "--------------------------------------------------------------------------------------"
                Write-TimeHost " COMMAND BackupToAAD-BitLockerKeyProtector failed!"
                Write-TimeHost " Saving key protector to AAD for self-service recovery by manually posting it to:"
                Write-TimeHost "                     https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
                Write-Host "--------------------------------------------------------------------------------------"
                # Get the BitLocker key information from WMI
                (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector|Where-Object{$_.KeyProtectorType -eq 'RecoveryPassword'} | ForEach-Object{
                    $key = $_
                    write-verbose "kid : $($key.KeyProtectorId) key: $($key.RecoveryPassword)"
                    $body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}"
        
                    # Create the URL to post the data to based on the tenant and device information
                    $url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
        
                    # Post the data to the URL and sign it with the AAD Machine Certificate
                    Write-TimeDebug "Execute 'Invoke-WebRequest to Graph API"
                    $req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert
                    $req.RawContent
                    Write-Host "--------------------------------------------------------------------------------------"
                    Write-TimeHost " -- Key save web request sent to AAD - Self-Service Recovery should work"
                    Write-Host "--------------------------------------------------------------------------------------"
                }
            }
        
            #In case we had to encrypt, turn it on for any enabled volume
            Resume-BitLocker -MountPoint $OSDrive
        
            # --------------------------------------------------------------------------
            #  Finish - Let's dump the ending point
            # --------------------------------------------------------------------------
            Write-Host "--------------------------------------------------------------------------------------"
            Write-TimeHost " ENDING POINT:  Get-BitLockerVolume $OSDrive"
            Write-Host "--------------------------------------------------------------------------------------"
            $bdeProtect = Get-BitLockerVolume $OSDrive 
        
            #>
        } 
        catch 
        { 
            Write-Error "Error while setting up AAD Bitlocker, make sure that you are AAD joined and are running the cmdlet as an admin: $_" 
            Invoke-ClosingTasks -Reason error
        }
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    $EndProcessDate = Get-Date

#endregion
#############################################################################################
#region final area
    Write-TimeHost "Final Area"
    Write-Host "#############################################################################################"

    # calculate ScriptDuration
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    $PreStepsDuration = $EndPreStepsDate - $StartPreStepsDate
    $ProcessDuration = $EndProcessDate - $StartProcessDate

    $PreDur = -join ([math]::Ceiling($PreStepsDuration.TotalMinutes), " Minutes")
    $ProcDur = -join ([math]::Ceiling($ProcessDuration.TotalMinutes), " Minutes")
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    # print ScriptDuration
    Write-TimeHost "Duration of Presteps: $PreDur"
    Write-TimeHost "Duration of Processing: $ProcDur"
    Write-TimeDebug "Execute 'Invoke-ClosingTasks'..."
    
    Invoke-ClosingTasks -Reason finished
#endregion
#===================================================================================================================
