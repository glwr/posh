workflow ShutDownStartByTag
{
        Param(
        [Parameter(Mandatory=$true)]
        [String]
        $TagName,
        [Parameter(Mandatory=$true)]
        [String]
        $TagValue,
        [Parameter(Mandatory=$true)]
        [Boolean]
        $Shutdown
        )
     
    $connectionName = "GREAUTOMATION";
 
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationPSCredential -Name 'GREAUTOMATION'  
 
        "Logging in to Azure..."
        Login-AzureRMAccount $servicePrincipalConnection
    }
    catch {
 
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
         
     
    $vms = Find-AzureRmResource -TagName $TagName -TagValue $TagValue | where {$_.ResourceType -like "Microsoft.Compute/virtualMachines"}
     
    Foreach -Parallel ($vm in $vms){
        
        if($Shutdown){
            Write-Output "Stopping $($vm.Name)";        
            Stop-AzureRmVm -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force;
        }
        else{
            Write-Output "Starting $($vm.Name)";        
            Start-AzureRmVm -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName;
        }
    }
}