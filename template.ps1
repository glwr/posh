<#
.SYNOPSIS

.DESCRIPTION

.NOTES
    Company     : Glück & Kanja
    Creation    : xx/xx/20xx
    Author      : glwr
    Requires    : PowerShell Core 6

.LINK

.EXAMPLE

#># SYNOPSIS
#############################################################################################
#region ProgramInfo

[string]$Script:ProgramName = "NameOfTheScriptOrProgram"
[Version]$Script:ProgramVersion = ""
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

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region variables
        ## define your variables here
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
    
        ##----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ## put your code here!
        ##----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    }
    catch
    {
        $CatchError = $true
    }
    finally
    {
        if($CatchError -eq $true)
        {
            Invoke-ClosingTasks -Reason error
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
