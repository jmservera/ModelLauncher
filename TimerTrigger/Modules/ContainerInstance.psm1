function Start-Container($ResourceGroupName, $JobId, $TriggerMetadata, $Location) {
    $env1 = New-AzContainerInstanceEnvironmentVariableObject -Name "JobId" -Value $JobId
    # todo: check max length of container name
    $containerName = [uri]::EscapeDataString($JobId) # escape special characters
    $container = New-AzContainerInstanceObject -Name $containerName -Image alpine -RequestCpu 1 -RequestMemoryInGb 1.5 `
        -EnvironmentVariable @($env1) `
        -Command ("echo","$($JobId): $TriggerMetadata at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        #-Command ("printenv")

    if (-not $Location) {
        $Location = $(Get-AzResourceGroup -ResourceGroupName $ResourceGroupName).Location
    }

    Write-Host "Starting container $containerName in resource group $ResourceGroupName at $Location"
    # TODO: container group name can be fixed to improve performance but at the risk of not being able to run multiple jobs at the same time
    $containerGroup = New-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $containerName `
        -Container $container -OsType Linux `
        -Location $Location -RestartPolicy Never
    # if($containerGroup){
    #     Write-Host " $containerName started"
    # }
    # else{
    #     Write-Warning " $containerName failed to start"
    # }    
}

Export-ModuleMember -Function Start-Container


