#region initialise

# set script name
$scriptname = $MyInvocation.MyCommand.Name
# Debug $scriptname = "DisableMeteredConnection.ps1"

# initialize logging
$logroot = "C:\Install\"
$logdate = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logfolder= -join ($logroot, "\", $scriptname)
$logfile = -join ($logfolder, "\", $logdate, "_", $scriptname, ".log")

# test if log path already available
if(!(Test-Path $logfolder))
{
    # create log directory
    New-Item -Path $logroot -Name $scriptname -ItemType Directory
}

# start logging
Start-Transcript -Path $logfile -Force

# script Infos

Write-Host "--------------------------------------------------------------------------------------"
Write-Host  "title: disable metered connection"
Write-Host  "created: 06/24/2019"
Write-Host  "by: Gerrit Reinke (Glück & Kanja)"
Write-Host  "version: 1.1"
Write-Host "--------------------------------------------------------------------------------------"

# detect local admin group (english or german)
$EN_Admin = "Administrators"
$DE_Admin = "Administratoren"


if((Get-LocalGroup | ? {$_.Name -eq $EN_Admin})) # check if english groupname is available
{
    [System.Security.Principal.NTAccount]$LocalAdminGroupName = (Get-LocalGroup | ? {$_.Name -eq $EN_Admin}).Name # set variable for later use
}
elseif((Get-LocalGroup | ? {$_.Name -eq $DE_Admin})) # check if german groupname is available
{
    [System.Security.Principal.NTAccount]$LocalAdminGroupName = (Get-LocalGroup | ? {$_.Name -eq $DE_Admin}).Name # set variable for later use
}
else
{
    # Find no defined group, exit script
    Write-Error -Message "No local admin group found! Exit execution..." -Category ObjectNotFound -RecommendedAction Exit
    Stop-Transcript
    Exit
}

# [System.Security.Principal.NTAccount]$LocalAdminGroupName = "SYSTEM" # if you would change to SYSTEM not to local admin group 

#endregion

#region enable Ownership privilege

function Enable-Privilege {
 param(
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

#endregion

#region Change Access to Administrators group

# enable take Ownership
# Enable-Privilege SeRestorePrivilege # if you would change to SYSTEM not to local admin group 
Enable-Privilege SeTakeOwnershipPrivilege 

# Change Owner to the local Administrators group
$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership)
$regACL = $regKey.GetAccessControl()
$regACL.SetOwner([System.Security.Principal.NTAccount]$LocalAdminGroupName)
$regKey.SetAccessControl($regACL)

# Change Permissions for the local Administrators group
$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
$regACL = $regKey.GetAccessControl()
$regRule = New-Object System.Security.AccessControl.RegistryAccessRule ($LocalAdminGroupName,"FullControl","ContainerInherit","None","Allow")
$regACL.SetAccessRule($regRule)
$regKey.SetAccessControl($regACL)

#endregion

#region change reg key

# Set key to disable metered connection for 3G
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" -Name "3G" -Value 0 # value 0 prevent users from change the value with the gui

# Set key to disable metered connection for 4G
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost" -Name "4G" -Value 0 # value 0 prevent users from change the value with the gui

#endregion

#region change access to defaults

# enable privilege restore
Enable-Privilege SeRestorePrivilege

# Change Permissions for the local Administrators group
$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
$regACL = $regKey.GetAccessControl()
$regRule = New-Object System.Security.AccessControl.RegistryAccessRule ($LocalAdminGroupName,"QueryValues,EnumerateSubKeys,ReadPermissions,ReadKey","ContainerInherit","None","Allow")
$regACL.SetAccessRule($regRule)
$regKey.SetAccessControl($regACL)

# Change Owner to TrustedInstaller group
$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\DefaultMediaCost",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership)
$regACL = $regKey.GetAccessControl()
$regACL.SetOwner([System.Security.Principal.NTAccount]"NT SERVICE\TrustedInstaller")
$regKey.SetAccessControl($regACL)

#endregion

#region end

Enable-Privilege SeTakeOwnershipPrivilege -Disable
Enable-Privilege SeRestorePrivilege -Disable

Stop-Transcript
Exit

#endregion
