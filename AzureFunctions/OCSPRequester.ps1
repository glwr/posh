<#
.SYNOPSIS

.DESCRIPTION

.NOTES
    Company     : Glück & Kanja
    Creation    : 05/04/2020
    Author      : glwr
    Requires    : PowerShell Core 6

.LINK

.EXAMPLE

#># SYNOPSIS
##===================================================================================================================
#region ProgramInfo

[string]$Script:ProgramName = "OCSPRequester"
[Version]$Script:ProgramVersion = "0.0.1"
[boolean]$Debug = $false
[boolean]$Verbose = $false
[boolean]$Warning = $false

#endregion
##===================================================================================================================
#region Pre Steps

    $StartPreStepsDate = Get-Date

    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region initialize logging

        ## check if warning messages should be printed or silently continued
        if($Warning){$WarningPreference = "Continue"}else{$WarningPreference = "SilentlyContinue"}
        ## check if verbose messages should be printed or silently continued
        if($Verbose){$VerbosePreference = "Continue"}else{$VerbosePreference = "SilentlyContinue"}
        ## check if debug, verbose and warning messages should be printed or silently continued
        if($Debug){$DebugPreference = "Continue";$VerbosePreference = "Continue";$WarningPreference = "Continue"}else{$DebugPreference = "SilentlyContinue"}
        
        ## define log root folder # if realmjoin is available set to "C:\Windows\Logs\RealmJoin\Packages"
        $LogRoot = "C:\Windows\Logs\RealmJoin\Packages"
        ## time stamp for log file name
        $LogDate = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
        ## sub folder where logs will be saved
        $LogFolder= -join ($LogRoot, "\", $ProgramName)
        ## full path of the log file
        $LogFile = -join ($LogFolder, "\", $LogDate, "_", $ProgramName, ".log")
        
        ## test if log path already available
            if(!(Test-Path $LogFolder))
            {
                ## create log directory
                New-Item -Path $LogRoot -Name $ProgramName -ItemType Directory
            }

        ## start logging
            Start-Transcript -Path $LogFile -Force

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region Function Area
        ## if you have some functions, declare them in this region
       function Get-GREPoShBasic
       { 
           <#
            .SYNOPSIS
                Load some Basic functions. 

            .DESCRIPTION
                For all common functions I reuse in multiple scripts I centralized it in a Basic functions script.

            .NOTES
                Creation    : 09/06/2019
                Author      : glwr
                Requires    : PowerShell  6

            .LINK

            .EXAMPLE

                Get-GREPoShBasic

            #># SYNOPSIS

            $CheckIfOnline =
            {
                $ErrorActionPreference = "SilentlyContinue"
                $WebResponse = Invoke-WebRequest -Method Get -Uri "https://raw.githubusercontent.com"
                $ErrorActionPreference = "Continue"
                if($WebResponse.StatusCode -eq 200)
                {
                    return $true
                }
                else 
                {
                    return $false   
                }
            }

            if(($PSVersionTable.PSVersion -lt "6.0.0") -and ($PSVersionTable.PSVersion -ge "5.0.0"))
            {
                    Write-Host "PS Version lower than 6, set `$IsWindows to `$true."
                    $IsWindowsButOldPoSh = $true
            }
            elseif ($PSVersionTable.PSVersion -lt "5.0.0") 
            {
                    Write-Host "PS Version is lower than 5, we will exit the execution. Please Update Windows PowerShell!"
                    Exit 1
            }

            if($IsMacOS -eq $true)
            {  
                Write-Host "MacOS detected"
                $PoShModulePath = "$env:HOME/.local/share/powershell/Modules"
                $GREPoSHBasicPath = "$PoShModulePath/GRE-PoSh-Basic/"
            }
            elseif ($IsLinux -eq $true)
            {
                Write-Host "Linix not supported/tested. We will exit."
                Exit 1
            } 
            elseif(($IsWindows -eq $true) -or ($IsWindowsButOldPoSh -eq $true))
            {
                Write-Host "Windows detected"
               $PoShModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
               $GREPoSHBasicPath = "$PoShModulePath\GRE-PoSh-Basic\"
            }
            else 
            {
                Write-Error "No OS detected. We will close this execution."
                Exit 1
            }

            if((Invoke-Command -ScriptBlock $CheckIfOnline) -eq $true)
            {
                Write-Host "We are online, download GRE PoSh Basic ps1..."
                $Null = New-Item -Path $GREPoSHBasicPath -ItemType Directory -Force
                Invoke-RestMethod -Uri "https://raw.githubusercontent.com/glwr/posh/master/Modules/GRE-PoSh-Basic/GRE-PoSh-Basic.psd1" -OutFile (-join ($GREPoSHBasicPath, "GRE-PoSh-Basic.psd1"))
                Invoke-RestMethod -Uri "https://raw.githubusercontent.com/glwr/posh/master/Modules/GRE-PoSh-Basic/GRE-PoSh-Basic.psm1" -OutFile (-join ($GREPoSHBasicPath, "GRE-PoSh-Basic.psm1"))
            }
            else
            {
                Write-Host "No network connection available, continue with Offline Module if available..."    
            }

            if((Get-Module GRE-PoSh-Basic -ListAvailable))
            {
                Write-Host "Import GRE PoSh Basic..."
                Import-Module GRE-PoSh-Basic
            }
            else
            {
                Write-Error -Message "Error during load GRE Basics- Module not available."
                Exit 1
            }
       }

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region script blocks
        ## if you have some script blocks, declare them in this region

        <#
        $ClosingTasksOnFinish = 
        {
            ## Executed by Invoke-ClosingTasks -Reason finished
        }
        #>

         <#
        $ClosingTasksOnError = 
        {
            ## Executed by Invoke-ClosingTasks -Reason error
        }
        #>

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    $EndPreStepsDate = Get-Date
#endregion
##===================================================================================================================
#region process area
    Write-TimeHost "Process Area" -ForegroundColor DarkCyan
    Write-Host "#############################################################################################"

    ## Load GRE Basics from Github
        Get-GREPoShBasic -ErrorAction "Stop"
    
    $StartProcessDate = Get-Date
    ##----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     ## put your code here!

     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     if(!(Get-Module PSPKI))
     {
        Install-Module PSPKI -Scope CurrentUser -Force
     }

     $rootpath = "$env:USERPROFILE\OneDrive - Glück & Kanja Consulting AG\Desktop\ocsp"
     $Certpath = "certs\clients\scepman-device-cert.cer"
     $ocspcert = -join ($rootpath, "\", $Certpath)

     workflow Start-Parallel-ocsps
     {
        Param
        (
            [Parameter(Mandatory=$true)]
            [String]
            $ocspcert
        )

        $parallel_worker = 1..5
        $request_count = 10

        foreach -parallel ($j in $parallel_worker)
        {
            for($i; $i -le $request_count;$i++)
            {
                InlineScript
                {
                    Import-Module PSPKI
                    $Request = New-Object pki.ocsp.ocsprequest $using:ocspcert
                    $Request.SendRequest()
                }
            }
        }
     }
     
     Start-Parallel-ocsps -ocspcert $ocspcert

    ##----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    $EndProcessDate = Get-Date

#endregion
##===================================================================================================================
#region final area
    Write-TimeHost "Final Area" -ForegroundColor DarkCyan
    Write-Host "#############################################################################################"

    ## calculate ScriptDuration
    ##----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    $PreStepsDuration = $EndPreStepsDate - $StartPreStepsDate
    $ProcessDuration = $EndProcessDate - $StartProcessDate

    $PreDur = -join ([math]::Ceiling($PreStepsDuration.TotalMinutes), " Minutes")
    $ProcDur = -join ([math]::Ceiling($ProcessDuration.TotalMinutes), " Minutes")
    $ScriptDur = [math]::Ceiling($PreStepsDuration.TotalMinutes) + [math]::Ceiling($ProcessDuration.TotalMinutes)
    ##----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    ## print ScriptDuration
    Write-TimeHost "Duration of Presteps: $PreDur" -ForegroundColor DarkCyan
    Write-TimeHost "Duration of Processing: $ProcDur" -ForegroundColor DarkCyan
    Write-TimeHost "Duration of overall Program: $ScriptDur" -ForegroundColor DarkCyan
    Write-TimeDebug "Execute 'Invoke-ClosingTasks'..."
    
    Invoke-ClosingTasks -Reason finished
#endregion
##===================================================================================================================
