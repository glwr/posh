<#
.SYNOPSIS

.DESCRIPTION

.NOTES
    Company     : Glück & Kanja
    Creation    : 08/20/2019
    Author      : glwr
    Requires    : PowerShell  6

.LINK

.EXAMPLE

#># SYNOPSIS
#############################################################################################
#region ProgramInfo

[string]$Script:ProgramName = "Compare-AzureADGroupMembers"
[Version]$Script:ProgramVersion = "0.0.1"
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
        $LogRoot = "C:\Temp\Logs"
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

        function Draw-Menu {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)]
                [pscustomobject]$menuState
            )
            
            begin {
            }
            
            process {
                if ($menuState.Items.count -eq 0){
                    return
                }
        
                # start draw
                [System.Console]::CursorTop = $menuState.CursorTop
                [System.Console]::CursorLeft = 0 # start on the left
        
                Write-Verbose ([System.Console]::CursorTop)
                
                $row = 1
                $column = 1
                $index = 0
                foreach ($item in $menuState.Items){
                    if ($index -eq $menuState.Selected){
                        Write-Host -NoNewline (
                            $item.PadRight($menuState.ColumnWidth)
                        )
                    } else {
                        Write-Host -NoNewline (
                            $item.PadRight($menuState.ColumnWidth)
                        )
                    }
                    $column++
                    $index++
                    if ($column -gt $menuState.Columns){
                        $row++
                        $column = 1
                        Write-Host ''
                    }
                }
        
                Write-Verbose ([System.Console]::CursorTop)
                
            }
            
            end {
            }
        }
        function Update-MenuStateByKey {
            [CmdletBinding()]
            param (
                [pscustomobject]$MenuState,
                [System.ConsoleKey]$Key
            )
            
            begin {
                
            }
            
            process {
                Write-Verbose $Key
                switch ($Key){
                    ([System.ConsoleKey]::RightArrow) {
                        $MenuState.Selected = $MenuState.Selected + 1
                    }
                    ([System.ConsoleKey]::LeftArrow) {
                        $MenuState.Selected = $MenuState.Selected - 1
                    }
                    ([System.ConsoleKey]::UpArrow) {
                        $MenuState.Selected = $MenuState.Selected - $MenuState.Columns
                    }
                    ([System.ConsoleKey]::DownArrow) {
                        $MenuState.Selected = $MenuState.Selected + $MenuState.Columns
                    }
                }
        
                # now do some bad value correcting
                if ($MenuState.Selected -gt ($MenuState.Items.Count -1 )){
                    $MenuState.Selected = $MenuState.Items.Count -1 #count is 1 indexed
                }
                if ($MenuState.Selected -lt 0){
                    $MenuState.Selected = 0
                }
            }
            
            end {
                return $MenuState
            }
        }

        function Show-ChoiceConsoleMenu {
            [CmdletBinding()]
            param (
                [String[]]$ItemList
            )
            
            begin {
                # create a state object with defaults
                $MenuState = New-Object pscustomobject -Property @{
                    CursorTop   = [System.Console]::CursorTop
                    Selected    = 0
                    Columns     = 1
                    ColumnWidth = [System.Console]::BufferWidth # default
                    Items       = $ItemList
                    Rows        = 0 #never used but might be nice to have
                }
        
                # calculate display grid.
                $ItemMaxLength = 0
                foreach ( $Item in $ItemList){
                    $ItemMaxLength = [math]::Max($Item.length,$ItemMaxLength)
                }
                $ItemMaxLength++ # create a single char buffer between columns
        
                if ($ItemMaxLength -lt [System.Console]::BufferWidth){
                    $MenuState.ColumnWidth = $ItemMaxLength
                }
                $MenuState.Columns = [int]([Math]::Max( 
                    [Math]::Floor( ( [System.Console]::BufferWidth / $ItemMaxLength ) )
                    , 1 ) )
                $MenuState.Rows = [int][Math]::Ceiling( ($ItemList.Count / $MenuState.Columns) )
        
                if ( [System.Console]::CursorTop + $MenuState.Rows -ge [System.Console]::BufferHeight ) {
                    if ((Read-Host "No enough buffer to show menu, clear screen? (Y/n)") -match '[nN][oO]?'){
                        Write-Warning "Console Buffer full, menu will act funny."
                    } else {
                        Clear-Host
                    }
                    $MenuState.Cursortop = [System.Console]::CursorTop
                }
        
            }
            
            process {
        
                # main iteraction loop
                [System.console]::CursorVisible=$false
                do {
                    Draw-Menu $MenuState
                    Write-Verbose $MenuState.Selected
                    $CursorBottom = [System.Console]::CursorTop
                    $MenuKey = [System.Console]::ReadKey($true)
                    $MenuState = Update-MenuStateByKey -MenuState $MenuState -Key $MenuKey.Key
                } while ($MenuKey.Key -ne [System.ConsoleKey]::Enter -and $MenuKey.Key -ne [System.ConsoleKey]::Escape)
                
        
                # clear menu
                $RowsToClear = $CursorBottom - $MenuState.CursorTop +1
                [System.Console]::CursorTop = $MenuState.CursorTop
                [System.Console]::CursorLeft = 0
                for ($ClearRow=0;$ClearRow -lt $RowsToClear;$ClearRow++){
                    Write-Host (''.PadRight( [System.Console]::BufferWidth, [char]160 ) ) #nbsp
                }
                # move cursor back to top, to stop big gap
                [System.Console]::CursorTop = $MenuState.CursorTop
                [System.console]::CursorVisible=$true
            }
            
            end {
                if ($MenuKey.Key -eq [System.ConsoleKey]::Enter) {
                    return $ItemList[$MenuState.Selected]
                }
            }
        }

    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region script blocks
        # if you have some script blocks, declare them in this region
    #endregion
    #----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #region variables
        # An comma separated list of Profile Groups
        [array]$ProfileGroupList = "sg_IntuneProfile.Aussendienst"
        [boolean]$SyncUsers = $true
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

    try
    {
        # set execution policy for this process
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

        ## Check PS Version
 
        if($PSVersionTable.PSVersion -lt "6.0.0")
        {
                Write-TimeHost "PS Version lower than 6, set `$IsWindows to `$true."
                $IsWindows = $true
        }
        elseif ($PSVersionTable.PSVersion -lt "5.0.0") 
        {
                Write-TimeHost "PS Version is lower than 5, we will exit the execution. Please Update Windows PowerShell!"
                Invoke-ClosingTasks -Reason error
        }

        # Install the AzureAD Module for current user
        if($IsWindows -eq $false)
        {
            Write-TimeHost "Running AzureAD Core Module because we are not on a Windows System"
            if(!(Get-PackageSource -Name "Posh Test Gallery" -ErrorAction SilentlyContinue))
            {
                Register-PackageSource -Trusted -ProviderName "PowerShellGet" -Name "Posh Test Gallery" -Location "https://www.poshtestgallery.com/api/v2/"
            }
            Install-Module -Name AzureAD.Standard.Preview -AllowClobber -Scope CurrentUser
            Import-Module -Name AzureAD.Standard.Preview
        }
        elseif($IsWindows -eq $true)
        {
            Write-TimeHost "Running AzureAD default Module because we are on a Windows System"
            Install-Module -Name AzureAD -AllowClobber -Scope CurrentUser
        }

        # connect to azure ad
        Connect-AzureAD

        # Prompt for Azure AD Group
        if($IsWindows -eq $true)
        {
            $ProfileGroup = $ProfileGroupList | Out-GridView -OutputMode Single -Title "Choose a Profile Group: "
        }
        elseif($IsWindows -eq $false)
        {
            Write-TimeHost "Please select one of this Groups, use your arrow keys to select."
            Write-TimeHost "To choose the first entry, press enter, to selecet the secound press arrrow key right and then enter, and so on..."
            $ProfileGroup  = Show-ChoiceConsoleMenu -ItemList $ProfileGroupList
        }

        # check if Group is available
        $AADGroupObject = Get-AzureADGroup -SearchString $ProfileGroup -All:$true

        $ProfileGroupMembers = Get-AzureADGroupMember -ObjectId $AADGroupObject.ObjectId -All:$true

        # filter Groupmembers
        [array]$ProfileGroupMemberUsers = $null
        [array]$ProfileGroupMemberGroups = $null

        foreach($GroupMember in $ProfileGroupMembers)
        {
            if($GroupMember.ObjectType -eq "User")
            {
                [array]$ProfileGroupMemberUsers += $GroupMember
            }
            if($GroupMember.ObjectType -eq "Group")
            {
                [array]$ProfileGroupMemberGroups += $GroupMember
            }
        }

        Write-Host "########################################################################################"
        Write-TimeHost "Count of Users in Profile " -ForegroundColor Cyan -NoNewline
        Write-Host  $($AADGroupObject.DisplayName) -ForegroundColor Green
        $ProfileGroupMemberUsers.Count
        Write-TimeHost "List of Users in Profile " -ForegroundColor Cyan -NoNewline
        Write-Host  $($AADGroupObject.DisplayName) -ForegroundColor Green
        $ProfileGroupMemberUsers | Select-Object UserPrincipalName
        Write-TimeHost "User Sync is set to " -ForegroundColor Cyan -NoNewline
        Write-Host  $($SyncUsers) -ForegroundColor Green

        Write-Host "########################################################################################"
        Write-TimeHost "CompareGroups and Add missing users" -ForegroundColor Cyan
        Write-Host "-----------------------------------------------------------------------------------------"
        
        foreach($Group in $ProfileGroupMemberGroups)
        {
            $GroupMembers = Get-AzureADGroupMember -ObjectId $Group.ObjectId -All:$true
            Write-TimeHost "Compare $($Group.DisplayName) with $($AADGroupObject.DisplayName)" -ForegroundColor Cyan
            Write-TimeHost "Show Users that are not Members of " -ForegroundColor Cyan -NoNewline
            Write-Host  $($Group.DisplayName) -ForegroundColor Green
            $ComparedObjects = Compare-Object -ReferenceObject $GroupMembers -DifferenceObject $ProfileGroupMemberUsers -PassThru | Where-Object {$_.SideIndicator -eq "=>"}
            Compare-Object -ReferenceObject $GroupMembers -DifferenceObject $ProfileGroupMemberUsers -Property "UserPrincipalName" | Where-Object {$_.SideIndicator -eq "=>"} | Format-Table
            Write-Host "-----------------------------------------------------------------------------------------"
        
            if($SyncUsers -eq $true)
            {
                foreach($MissingUser in $ComparedObjects)
                {
                    Add-AzureADGroupMember -ObjectId $Group.ObjectId -RefObjectId $MissingUser.ObjectId
                }
            }
        }

        Write-Host "########################################################################################"
        Write-TimeHost "Compare Groups and show Equal Users" -ForegroundColor Cyan
        Write-Host "-----------------------------------------------------------------------------------------"
        
        foreach($Group in $ProfileGroupMemberGroups)
        {
            $GroupMembers = Get-AzureADGroupMember -ObjectId $Group.ObjectId -All:$true
            Write-TimeHost "Compare $($Group.DisplayName) with $($AADGroupObject.DisplayName)" -ForegroundColor Cyan
            Write-Host  $($Group.DisplayName) -ForegroundColor Green
            Compare-Object -ReferenceObject $GroupMembers -DifferenceObject $ProfileGroupMemberUsers -Property "UserPrincipalName" -IncludeEqual | Where-Object {($_.SideIndicator -eq "=>") -or ($_.SideIndicator -eq "==")} | Format-Table
            Write-Host "-----------------------------------------------------------------------------------------"
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
