<#
.SYNOPSIS
    Common Functions I use in many scripts.

.DESCRIPTION

.NOTES
    Creation    : 09/06/2019
    Author      : glwr
    Requires    : PowerShell  6

.LINK

.EXAMPLE

#># SYNOPSIS

[Version]$GREPoShToolsVersion = "1.0.0.3"

function Send-OCSPRequests
{
    <#
    .SYNOPSIS
        Send OCSP request to an endpoint specified in a ".cer"-File

    .DESCRIPTION
        To simulate load tests for SCEPman you can use this tool.
        Requirements are that you have exported the root and a device or user certifiacte
        from an Intune managed machine, which has received his certifiactes from SCEPman.

        Please import the root certifiacte into the machine trusted root certificates store!

    .NOTES
        Creation    : 05/14/2020
        Author      : glwr
        Requires    : PowerShell  6

    .LINK

    .EXAMPLE

        1. Send 1200 OCSP requests with 12 parallel workers with a delay of 5 secounds between each worker and an idle time of 3 secounds between each request.
            Send-OCSPRequests -CertPath "C:\Temp\scepman-user-cert.cer"
        2. Send 2400 OCSP requests with 24 parallel workers with a delay of 10 secounds between each worker and an idle time of 4 secounds between each request.
            Send-OCSPRequests -CertPath "C:\Temp\scepman-user-cert.cer" -Worker 24 -StartUpDelay 10 -Requests 2400 -WorkerIdleTime 4

    #># SYNOPSIS
    
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
    #############################################################################################
    
    #region parameters
    param
    (
        ## Path to the ".cer" file.
        [Parameter(Mandatory=$true)]
        [string]$CertPath,
        ## Count of parallel worker.
        [Parameter(Mandatory=$false)]
        [int]$Worker = 12,
        ## Delay between the worker start up in secounds.
        [Parameter(Mandatory=$false)]
        [int]$StartUpDelay = 5,
        ## Count of ocsp request for each worker.
        [Parameter(Mandatory=$false)]
        [int]$Requests = 1200,
        ## Idle time between each ocsp request in secounds.
        [Parameter(Mandatory=$false)]
        [int]$WorkerIdleTime = 3
    )
    #endregion
    #############################################################################################
    #region ProgramInfo

    [string]$Script:ProgramName = "Send-OCSPRequests"
    [Version]$Script:ProgramVersion = "1.0.1"
    [boolean]$Debug = $false
    [boolean]$Verbose = $false
    [boolean]$Warning = $false

    #endregion
    #############################################################################################
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
            
            $CreateOCSPRequest = 
            {
                Param
                (
                    [Parameter(Mandatory=$true)]
                    [String]
                    $CertPath,
                    [Parameter(Mandatory=$true)]
                    [int]
                    $Requests,
                    [Parameter(Mandatory=$false)]
                    [int]
                    $WorkerIdleTime
                )

                Import-Module PSPKI
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

                for($i; $i -lt $Requests;$i++)
                {
                    $Request = New-Object pki.ocsp.ocsprequest $CertPath
                    $Request.SendRequest()
                    Start-Sleep -Seconds $WorkerIdleTime
                }
            }

        #endregion
        #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        #region variables
            ## define your variables here
            [array]$Worker = 1..$Worker
        #endregion
        #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        $EndPreStepsDate = Get-Date
    #endregion
    #############################################################################################
    #region process area
        Write-Host "Process Area" -ForegroundColor DarkCyan
        Write-Host "#############################################################################################"

        $StartProcessDate = Get-Date
        #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        try 
        {
            ## set execution policy for this process
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

            ## Load GRE Basics from Github
                $RemoteCode = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/glwr/posh/master/Modules/Get-ModulesLoader.ps1" 
                Invoke-Expression $RemoteCode
                Get-GREPoShBasic -ErrorAction "Stop" 

            ## Install the PSPKI Module
            if(!(Get-Module PSPKI))
            {
                Install-Module PSPKI -Scope CurrentUser -Force
            }

            ## test if we can send ocsp requests
                Invoke-Command -ScriptBlock $CreateOCSPRequest -ArgumentList $CertPath, 1, 1

            ## start workers to send ocsp requests
                foreach($j in $Worker)
                {
                    Start-Job -ScriptBlock $CreateOCSPRequest -ArgumentList $CertPath, $Requests, $WorkerIdleTime
                    Start-Sleep -Seconds $StartUpDelay
                }
        }
        catch
        {
            $CatchError = $true
        }
        finally
        {
            if($CatchError -eq $true)
            {
                Invoke-ClosingTasks -Reason error -ErrorObject $Global:Error[0]
            }
        }

        #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        $EndProcessDate = Get-Date

    #endregion
    #############################################################################################
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
        #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        ## print ScriptDuration
        Write-TimeHost "Duration of Presteps: $PreDur" -ForegroundColor DarkCyan
        Write-TimeHost "Duration of Processing: $ProcDur" -ForegroundColor DarkCyan
        Write-TimeHost "Duration of overall Program: $ScriptDur" -ForegroundColor DarkCyan
        Write-TimeDebug "Execute 'Invoke-ClosingTasks'..."
        
        Invoke-ClosingTasks -Reason finished
    #endregion
    ##===================================================================================================================

}
