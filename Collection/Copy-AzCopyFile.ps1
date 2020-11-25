<#
.SYNOPSIS

.DESCRIPTION

.NOTES
    Company     : Glück & Kanja
    Creation    : 11/25/2020
    Author      : glwr
    Requires    : PowerShell 6

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
        $LogRoot = "C:\azcopy"
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

        ### customaziable variables
        # storage variables
        $storageaccname = "yoursotrageaccname"
        $sastoken = "?sv="
        $blobcontainer = '$root'

        # local variables
        $workingdir = "C:\azcopy"
        $filepath = "C:\azcopy"
        $filename = "testfile.txt"

        ### generated and fix variables
        $blobendpoint = ".blob.core.windows.net"
        $storageurl = -join ("https://", $storageaccname, $blobendpoint)
        $azcopyurl = (curl https://aka.ms/downloadazcopy-v10-windows -MaximumRedirection 0 -ErrorAction silentlycontinue -UseBasicParsing).headers.location
        $azcopy = "$workingdir\azcopy.exe"

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
            if(!(Test-Path $workingdir))
            {
                New-Item -Path $workingdir -ItemType Directory
            }

            if(!(Test-Path "$workingdir\azcopy.exe"))
            {
                Invoke-WebRequest -Uri $azcopyurl -OutFile "$workingdir\azcopy.zip" -UseBasicParsing
                Expand-Archive -Path "$workingdir\azcopy.zip" -DestinationPath $workingdir -Force
                $subfolder = Get-ChildItem -Path $workingdir -Directory | Where-Object {$_.Name -match "azcopy_windows_amd64"} 
                Copy-Item -Path (-join($workingdir, "\", $subfolder, "\*")) -Destination $workingdir -Recurse -Force
                Remove-Item -Path (-join($workingdir, "\", $subfolder)) -Recurse -Force
                Remove-Item -Path "$workingdir\azcopy.zip" -Force
            }

            . $azcopy copy (-join ($filepath, "\", $filename)) (-join ($storageurl, "/", $blobcontainer, "/", $sastoken)) --recursive=true
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
