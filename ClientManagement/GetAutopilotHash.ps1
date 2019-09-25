mkdir c:\\HWID >> $null
Set-Location c:\\HWID 
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
Install-Script -Name Get-WindowsAutoPilotInfo -Force
Get-WindowsAutoPilotInfo.ps1 -OutputFile AutoPilotHWID.csv