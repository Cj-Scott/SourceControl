<#
    .DESCRIPTION
        A runbook which Stops VM's that are tagged with key of Priority and Value of 0 using the Run As Account (Service Principal)

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
Where-Object {$PSItem.Tags.Keys -eq "Priority" -and $PSItem.Tags.Values -eq "0" `
-and $PSItem.PowerState -eq "VM running"}
 
ForEach ($VM in $VMs) 
{
    Write-Output "Shutting down: $($VM.Name)"
    Stop-AzureRMVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Force
}     


