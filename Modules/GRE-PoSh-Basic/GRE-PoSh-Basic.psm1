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

[Version]$GREPoShBasicVersion = "1.0.0.1"

function Enable-Privilege 
{
    <#
    .SYNOPSIS
        Enable enhanced privilege for a process.

    .DESCRIPTION
        To do some actions on System or TrustedInstaller protected items.

    .NOTES
        Creation    : 09/06/2019
        Author      : glwr
        Requires    : PowerShell  6

    .LINK

    .EXAMPLE

        1. To enable a privilege for your process
            Enable-Privilege SeTakeOwnershipPrivilege
        2. To disable a privilege for your process
            Enable-Privilege SeTakeOwnershipPrivilege -Disable

    #># SYNOPSIS
    param
    (
        ## The privilege to adjust. This set is taken from
        ## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
        [ValidateSet(
        "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
        "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
        "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
        "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
        "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
        "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
        "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
        "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
        "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
        "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
        "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
        $Privilege,
        ## The process on which to adjust the privilege. Defaults to the current process.
        $ProcessId = $pid,
        ## Switch to disable the privilege, rather than enable it.
        [Switch] $Disable
    )

 ## Taken from P/Invoke.NET with minor adjustments.
 $definition = @'
 using System;
 using System.Runtime.InteropServices;
  
 public class AdjPriv
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
   ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
  {
   bool retVal;
   TokPriv1Luid tp;
   IntPtr hproc = new IntPtr(processHandle);
   IntPtr htok = IntPtr.Zero;
   retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
   tp.Count = 1;
   tp.Luid = 0;
   if(disable)
   {
    tp.Attr = SE_PRIVILEGE_DISABLED;
   }
   else
   {
    tp.Attr = SE_PRIVILEGE_ENABLED;
   }
   retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
   retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
   return retVal;
  }
 }
'@

    $processHandle = (Get-Process -id $ProcessId).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

function Set-RegKeyRights
{
    <#
    .SYNOPSIS
        Take ownership of regkey and/or set rights for these key.

    .DESCRIPTION
        If you want to take the ownership of a reg key and/or then grant a NT Account full control to it.

    .NOTES
        Creation    : 09/06/2019
        Author      : glwr
        Requires    : PowerShell  6

    .LINK

    .EXAMPLE

        1. if you want to take full control of the DefaultMediaCost key to the local Administrator Group
            Set-RegKeyRights -KeyPath "SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" -NTAccount "Administrators"

        2. If you want to take full control and ownership of the DefaultMediaCost key to the SYSTEM account
            Set-RegKeyRights -KeyPath "SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" -NTAccount "SYSTEM" -TakeOwnerShip

        3. Change to less powerfull rigths for the local Administrator Group
            Set-RegKeyRights -KeyPath "SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" -NTAccount "Administrators" -Rights "QueryValues,EnumerateSubKeys,ReadPermissions,ReadKey"
        
    #># SYNOPSIS

    param
    (
        ## Path to the reg key you want to change
        [String]
        $KeyPath,
        ## Name of the NT Account you want to give ownership and rights
        [System.Security.Principal.NTAccount]
        $NTAccount,
        ## comma seperated list of rights
        [string]
        $Rights = "FullControl",
        ## if you want to take ownership of the key
        [Switch]
        $TakeOwnerShip
    )
    
    ## Change Owner for the NT Account

    if($TakeOwnerShip -eq $true)
    {
        $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership)
        $regACL = $regKey.GetAccessControl()
        $regACL.SetOwner($NTAccount)
        $regKey.SetAccessControl($regACL)
    }

    ## Change permissons to full control for the NT Account

    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $regACL = $regKey.GetAccessControl()
    $regRule = New-Object System.Security.AccessControl.RegistryAccessRule ($NTAccount,$Rights,"ContainerInherit","None","Allow")
    $regACL.SetAccessRule($regRule)
    $regKey.SetAccessControl($regACL)

}

function Invoke-ClosingTasks
{
    <#
    .Synopsis
    Invoke Closing Task

    .Description
    Sets Exit State to either Finished or Error
    Required cleanup steps can be implemented via ScriptBlocks ($ClosingTasksOnFinish or $ClosingTasksOnError) in any script.

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

        ## check for scriptblock with additional tasks and execute it
        if($ClosingTasksOnFinish)
        {
            Invoke-Command -ScriptBlock $ClosingTasksOnFinish
        }
        
        Write-TimeHost "Execution finisehd. Closing Program..." -ForegroundColor Green
        Exit 0
    }
    elseif($Reason -eq "error")
    {
        Write-TimeDebug "Execution run on errors and will be closed..."

        Write-TimeHost -Message "Error CategoryInfo"  -ForegroundColor Red
        $Error[0].CategoryInfo
        Write-TimeHost -Message "Error Exception"  -ForegroundColor Red
        $Error[0].Exception
        Write-TimeHost -Message "Error FullyQualifiedErrorId"  -ForegroundColor Red
        $Error[0].FullyQualifiedErrorId
        Write-TimeHost -Message "Error InvocationInfo"  -ForegroundColor Red
        $Error[0].InvocationInfo
        Write-TimeHost -Message "Error ScriptStackTrace"  -ForegroundColor Red
        $Error[0].ScriptStackTrace

        ## check for scriptblock with additional tasks and execute it
        if($ClosingTasksOnError)
        {
            Invoke-Command -ScriptBlock $ClosingTasksOnError
        }

        Write-TimeHost "Execution run on errors and will be closed..." -ForegroundColor Red
        Exit 1
    }
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
