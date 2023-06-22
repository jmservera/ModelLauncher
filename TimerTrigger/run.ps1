# Input bindings are passed in via param block.
param($Timer)

class FunctionsContext {
    [object] $StorageContext
    [string] $ContainerName

    FunctionsContext([string]$StorageAccountName, [string]$StorageAccountKey, [string]$ContainerName) {
        $this.ContainerName = $ContainerName
        Write-Verbose "Connecting to Storage Account $StorageAccountName"
        if ( $StorageAccountName -eq "devstoreaccount1") {
            Write-Host "Using local storage account"
            $this.StorageContext = New-AzStorageContext -Local
        }
        else {
            if (-not $StorageAccountKey) {
                Write-Host "StorageAccountKey not provided, using connected account"
                $this.StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
            }
            else {
                $this.StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey        
            }
        }
    }

    # Get all files from a folder in the current Azure Storage
    [Object[]] GetAzureStorageFilesFromFolder([string]$Prefix) {
        return Get-AzStorageBlob -Container $this.ContainerName -Context $this.StorageContext -Prefix $Prefix
    }

    [Object] GetBlob([string]$Name) {
        return Get-AzStorageBlob -Container $this.ContainerName -Context $this.StorageContext -Blob $Name
    }

    [string] GetBlobText([string]$Name) {
        $container = Get-AzStorageContainer -Name $this.ContainerName -Context $this.StorageContext
        #Get reference for file
        $client = $container.CloudBlobContainer.GetBlockBlobReference($Name)
        #Read file contents into memory
        return $client.DownloadText()
    }

    # List all the .csv files in the upload folder
    [Object[]] GetNewCSVFiles() {
        return $this.GetAzureStorageFilesFromFolder("upload") | where-object { $_.Name -like "*.csv" }
    }

    # Checks if all the files listed in the csv file are present in the upload folder
    [bool] CheckAllFiles([string]$Name) {   
        $folder = Split-Path $Name -Parent

        # gets all the files in the folder
        $files = $this.GetAzureStorageFilesFromFolder($folder) #| where-object { $_.Name -notlike "*.csv" } # uncomment to exclude csv files

        # downloads and interprets the csv file
        $fileList = $this.GetBlobText($Name) | ConvertFrom-Csv -Delimiter "," -Header "filename","desc"

        # checks one by one if the listed files are present in the folder
        foreach($item in $fileList){
            $file = $files | where-object { $_.Name -like $folder + "/" + $item.filename }
            if ($null -eq $file) {
                Write-Verbose "File $($item.filename) is still missing in $($folder)!"
                return $false
            }
        }
        return $true
    }

}


# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}
$context = [FunctionsContext]::new($env:AzureAccountName, $env:AzureAccountKey, $env:ContainerName)
$files = $context.GetNewCSVFiles()

foreach ($item in $files) {
    if ($context.CheckAllFiles($item.Name)) {
        Write-Host "File $($item.Name) is ready to be processed!"
    }
}
# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"


