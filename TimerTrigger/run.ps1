using module ./Modules/Storage.psm1
using module ./Modules/ContainerInstance.psm1

# Input bindings are passed in via param block.
param($Timer)

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}
$context = [Storage]::new($env:AzureAccountName, $env:AzureAccountKey, $env:ContainerName)
$files = $context.GetNewMetadataFiles()

foreach ($item in $files) {
    if ($context.CheckAllFiles($item.Name)) {
        Write-Host "File $($item.Name) is ready to be processed, moving to processing folder!"
        if($context.MoveToProcessing($item.Name)){
            $workName = (Split-Path $item.Name -Parent | Split-Path -Leaf).ToLower()
            Write-Host "Processing $workName"            
            Start-Container $env:ResourceGroupName $workName "metadata or other params"
            Write-Host "Process $workName started asynchronously $((Get-Date).ToUniversalTime())"
        }
    }
}

Write-Host "PowerShell timer trigger function end $((Get-Date).ToUniversalTime())"
