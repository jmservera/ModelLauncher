function Start-Container($ResourceGroupName, $JobId, $TriggerMetadata, $Location) {
    $env1 = New-AzContainerInstanceEnvironmentVariableObject -Name "JobId" -Value $JobId
    $container = New-AzContainerInstanceObject -Name test-container -Image alpine -RequestCpu 1 -RequestMemoryInGb 1.5 `
        -EnvironmentVariable @($env1) `
        -Command ("printenv")
    #-Command ("echo","`"From source: $JobId From Env: `$JobId`"") `

    if (-not $Location) {
        $Location = $(Get-AzResourceGroup -ResourceGroupName $ResourceGroupName).Location
    }

    New-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $JobId `
        -Container $container -OsType Linux `
        -Location $Location -RestartPolicy Never
}

Export-ModuleMember -Function Start-Container


