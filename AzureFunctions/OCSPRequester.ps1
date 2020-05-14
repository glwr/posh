#### Define you parameters below ####

# Plase add your SCEPman root certifiacte to your machine trusted root store!

# Path to you ".cer" file, you can use a device or user certifiacte exported from one of your clients
$CertPath = "C:\Temp\scepman-user-cert.cer"

# count of parallel workers
$Worker = 24

# delay between each worker
$StartUpDelay = 10

# count of request each worker will send
$Requests = 1200

# idle time between each request
$WorkerIdleTime = 3

#####################################

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
function Get-GREPoShTools
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

        Get-GREPoShTools

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
        Invoke-RestMethod -Uri "https://raw.githubusercontent.com/glwr/posh/master/Modules/GRE-PoSh-Tools/GRE-PoSh-Tools.psd1" -OutFile (-join ($GREPoSHBasicPath, "GRE-PoSh-Basic.psd1"))
        Invoke-RestMethod -Uri "https://raw.githubusercontent.com/glwr/posh/master/Modules/GRE-PoSh-Tools/GRE-PoSh-Tools.psm1" -OutFile (-join ($GREPoSHBasicPath, "GRE-PoSh-Basic.psm1"))
    }
    else
    {
        Write-Host "No network connection available, continue with Offline Module if available..."    
    }

    if((Get-Module GRE-PoSh-Basic -ListAvailable))
    {
        Write-Host "Import GRE PoSh Tools..."
        Import-Module GRE-PoSh-Basic
    }
    else
    {
        Write-Error -Message "Error during load GRE Basics- Module not available."
        Exit 1
    }
}

## set execution policy for this process
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

## Load GRE Basics from Github
Get-GREPoShBasic -ErrorAction "Stop"
Get-GREPoShTools -ErrorAction "Stop"

Send-OCSPRequests -CertPath $CertPath  -Worker $Worker -StartUpDelay $StartUpDelay -Requests $Requests -WorkerIdleTime $WorkerIdleTime
