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
[Version]$Script:ProgramVersion = "0.0.3"
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
                    $IsWindows = $true
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
            elseif($IsWindows -eq $true)
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
        ## set execution policy for this process
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

        ## Load GRE Basics from Github
        Get-GREPoShBasic -ErrorAction "Stop"

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
