<#
    .DESCRIPTION
        A runbook which Starts VM's that are tagged with key of Priority and Value of 1 using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: CHSC
        LASTEDIT: October 26, 2016
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Login-AzureRmAccount -environment AzureUSGovernment `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

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

# Get all VMs in the subscription and Shut them down if they are running
[array]$VMs = Get-AzureRMVm -Status | `
Where-Object {$PSItem.Tags.Keys -eq "Priority" -and $PSItem.Tags.Values -eq "1" `
-and $PSItem.PowerState -eq "VM deallocated"}
 
ForEach ($VM in $VMs)
{
    Write-Output "Starting: $($VM.Name)"
    Start-AzureRMVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName
}    

Start-AzureRmAutomationRunbook -Name Startup-VMs_Priority2 -AutomationAccountName OPSMG01-OMS-Automation -ResourceGroupName opsmg01-oms

