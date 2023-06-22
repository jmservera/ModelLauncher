# Input bindings are passed in via param block.
param($Timer)

class FunctionsContext {
    [object] $StorageContext
    [string] $ContainerName

    FunctionsContext([string]$StorageAccountName,[string]$StorageAccountKey,[string]$ContainerName){
        $this.ContainerName=$ContainerName
        if ( $StorageAccountName -eq "devstoreaccount1") {
            $this.StorageContext = New-AzStorageContext -Local
        }
        else {
            if (-not $StorageAccountKey) {
                $this.StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
            }
            else {
                $this.StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey        
            }
        }
    }
}
function Get-AzureStorageFilesFromFolder {
    param(
        [Parameter(Mandatory = $true)]        
        [FunctionsContext]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    # List all the files in the container
    return Get-AzStorageBlob -Container $Context.ContainerName -Context $Context.StorageContext -Prefix $Prefix
}

function Get-NewCSVFiles {
    param(
        [Parameter(Mandatory = $true)]        
        [FunctionsContext]$Context,
        [Parameter(Mandatory = $false)]
        [string]$Prefix="upload"
    )
    return Get-AzureStorageFilesFromFolder -Context $Context -Prefix $Prefix | where-object {$_.Name -like "*.csv"}
}

function Check-AllFiles {
    param(
        [Parameter(Mandatory = $true)]
        [FunctionsContext]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    Split-Path $Name -Parent | Write-Host
    Split-Path $Name -Leaf | Write-Host

    return $false
}


# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}
$context = [FunctionsContext]::new($env:AzureAccountName,$env:AzureAccountKey,$env:ContainerName)
$files = Get-NewCSVFiles -Context $context

foreach ($item in $files) {
    if (Check-AllFiles -Context $context -Name $item.Name){
        Write-Host "File $item.Name is ready to be processed!"
    }
}
# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"


