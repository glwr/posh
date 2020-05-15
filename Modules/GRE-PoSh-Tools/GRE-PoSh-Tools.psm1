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

[Version]$GREPoShToolsVersion = "1.0.0.2"

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
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
                        $IsWindowsAndOldPS = $true
                }
                elseif ($PSVersionTable.PSVersion -lt "5.0.0") 
                {
                        Write-Host "PS Version is lower than 5, we will exit the execution. Please Update Windows PowerShell!"
                        Exit 1
                }
    
                if($IsMacOS -eq $true)
                {  
                    Write-Host "MacOS detected"
                    $PoShModulePath = $env:PSModulePath.Split(":")  | Where-Object {$_ -match "$env:USER/.local/share"}
                    $GREPoSHBasicPath = "$PoShModulePath/GRE-PoSh-Basic/"
                }
                elseif ($IsLinux -eq $true)
                {
                    Write-Host "Linix not supported/tested. We will exit."
                    Exit 1
                } 
                elseif(($IsWindows -eq $true) -or ($IsWindowsAndOldPS -eq $true))
                {
                    Write-Host "Windows detected"
                    $PoShModulePath = $env:PSModulePath.Split(";")  | Where-Object {$_ -match "Documents"}
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
            
            $CreateOCSPRequest = 
            {
                Param
                (
                    [Parameter(Mandatory=$true)]
                    [String]
                    $ocspcert,
                    [Parameter(Mandatory=$true)]
                    [int]
                    $request_count,
                    [Parameter(Mandatory=$false)]
                    [int]
                    $WorkerIdleTime
                )

                Import-Module PSPKI
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

                for($i; $i -lt $request_count;$i++)
                {
                    $Request = New-Object pki.ocsp.ocsprequest $ocspcert
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
                Get-GREPoShBasic -ErrorAction "Stop"

            if(!(Get-Module PSPKI))
            {
                Install-Module PSPKI -Scope CurrentUser -Force
            }

            # test if we can send ocsp requests

            Invoke-Command -ScriptBlock $CreateOCSPRequest -ArgumentList $CertPath, $request_count, $IdleTime

            # start workers to send ocsp requests
            foreach($j in $parallel_worker)
            {
                Start-Job -ScriptBlock $CreateOCSPRequest -ArgumentList $CertPath, $request_count, $IdleTime
                Start-Sleep -Seconds $StartUpDelay
            }
        }
        catch
        {
            Invoke-ClosingTasks -Reason error
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
