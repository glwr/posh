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
 
$RemoteCode = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/glwr/posh/master/Modules/Get-ModulesLoader.ps1" 
Invoke-Expression $RemoteCode

## set execution policy for this process
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

## Load GRE Basics from Github
Get-GREPoShBasic -ErrorAction "Stop"
Get-GREPoShTools -ErrorAction "Stop"

Send-OCSPRequests -CertPath $CertPath  -Worker $Worker -StartUpDelay $StartUpDelay -Requests $Requests -WorkerIdleTime $WorkerIdleTime
