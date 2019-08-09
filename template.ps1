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
            }
            elseif($Reason -eq "error")
            {
                Write-TimeDebug "Execution run on errors and will be closed..."
                Write-TimeHost "Execution run on errors and will be closed..." -ForegroundColor Red
            }

            # Exit
            Exit
        } 

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region script blocks
        # if you have some script blocks, declare them in this region

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    $EndPreStepsDate = Get-Date
#endregion
#############################################################################################
#region process area
    Write-TimeHost "Process Area" -ForegroundColor DarkCyan
    Write-Host "#############################################################################################"

    $StartProcessDate = Get-Date
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     # put your code here!
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    $EndProcessDate = Get-Date

#endregion
#############################################################################################
#region final area
    Write-TimeHost "Final Area" -ForegroundColor DarkCyan
    Write-Host "#############################################################################################"

    # calculate ScriptDuration
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    $PreStepsDuration = $EndPreStepsDate - $StartPreStepsDate
    $ProcessDuration = $EndProcessDate - $StartProcessDate

    $PreDur = -join ([math]::Ceiling($PreStepsDuration.TotalMinutes), " Minutes")
    $ProcDur = -join ([math]::Ceiling($ProcessDuration.TotalMinutes), " Minutes")
    $ScriptDur = [math]::Ceiling($PreStepsDuration.TotalMinutes) + [math]::Ceiling($ProcessDuration.TotalMinutes)
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    # print ScriptDuration
    Write-TimeHost "Duration of Presteps: $PreDur" -ForegroundColor DarkCyan
    Write-TimeHost "Duration of Processing: $ProcDur" -ForegroundColor DarkCyan
    Write-TimeHost "Duration of overall Program: $ScriptDur" -ForegroundColor DarkCyan
    Write-TimeDebug "Execute 'Invoke-ClosingTasks'..."
    
    Invoke-ClosingTasks -Reason finished
#endregion
#===================================================================================================================
