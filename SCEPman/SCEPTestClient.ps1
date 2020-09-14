
$DotNetInstallPS1DownloadURL = "https://dot.net/v1/dotnet-install.ps1"
## change URL to your SCEPman
$SCEPmanURL = "https://scepman.cldgkm.de/"

## Fix Vars
$SCEPClientURL = "https://cldlnk.de/DopvHz"
$SCEPClientRootPath = "$env:APPDATA\GKGAB\SCEPClient"
$DotnetInstallPS1 = -join ($SCEPClientRootPath, "\dotnet-install.ps1")
$SCEPClientEXE = -join ($SCEPClientRootPath, "\ScepClient.exe")
$SCEPCertsPath = -join ($SCEPClientRootPath, "\SCEPCerts")
$MSCEPDLLURL = -join ($SCEPmanURL, "certsrv/mscep/mscep.dll")
$DEBUGURL = -join ($SCEPmanURL, "debug")

## prepare work
Write-TimeHost "Test if SCEPClient root directory is available ..." -ForegroundColor Cyan -NoNewline
if(!(Test-Path -Path $SCEPClientRootPath))
{
    Write-TimeHost " ... SCEPClient root directory not found, create it ..." -ForegroundColor Cyan -NoNewline
    New-Item -Path $SCEPClientRootPath -ItemType Directory -Force

    Write-TimeHost "... download scepclient.exe ..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-RestMethod -Uri $SCEPClientURL -OutFile $SCEPClientEXE
}
Write-Host "... done" -ForegroundColor Green

Write-TimeHost "Test if SCEP certs directory is available ..." -ForegroundColor Cyan -NoNewline
if(!(Test-Path -Path $SCEPCertsPath))
{
    Write-TimeHost " ... scep certs directory not found, create it ..." -ForegroundColor Cyan -NoNewline
    New-Item -Path $SCEPCertsPath -ItemType Directory -Force
}
Write-Host "... done" -ForegroundColor Green

Write-TimeHost "Download dotnet-install.ps1 ..." -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod -Uri $DotNetInstallPS1DownloadURL -OutFile $DotnetInstallPS1

Write-TimeHost "Install Dot Net Core 3.1 ..." -ForegroundColor Cyan
. $DotnetInstallPS1 -Channel 3.1


## Download SCEPclient exe


# Normal Request ... 

. $SCEPClientEXE gennew $MSCEPDLLURL "$SCEPCertsPath\newcert.pfx" "$SCEPCertsPath\newcert.cer"

# Debug Request ...

. $SCEPClientEXE gennew $DEBUGURL "$SCEPCertsPath\newcert.pfx" "$SCEPCertsPath\newcert.cer"

