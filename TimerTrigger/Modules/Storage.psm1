class Storage {
    [object] $StorageContext
    [string] $ContainerName

    Storage([string]$StorageAccountName, [string]$StorageAccountKey, [string]$ContainerName) {
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
        $blob = $this.GetBlob($Name)
        #Read file contents into memory
        return $blob.ICloudBlob.DownloadText()
    }

    # List all the .csv files in the upload folder
    [Object[]] GetNewMetadataFiles() {
        return $this.GetAzureStorageFilesFromFolder("upload") | where-object { $_.Name -like "*_metadata.csv" }
    }

    # Checks if all the files listed in the csv file are present in the upload folder
    [bool] CheckAllFiles([string]$Name) {   
        $folder = Split-Path $Name -Parent

        # gets all the files in the folder
        $files = $this.GetAzureStorageFilesFromFolder($folder) #| where-object { $_.Name -notlike "*.csv" } # uncomment to exclude csv files

        # downloads and interprets the csv file
        $fileList = $this.GetBlobText($Name) | ConvertFrom-Csv -Delimiter ","

        # checks one by one if the listed files are present in the folder
        foreach($item in $fileList){
            if($item.Well){
                if($item.Assay){ # if assay is defined, check for assay files
                    $file = $files | where-object { $_.Name -like $folder + "/*_" + $item.Well +"_*.csv" }
                    if ($null -eq $file) {
                        Write-Warning "File $($item.Well) is still missing in $($folder)!"
                        return $false
                    }
                }
            }
            else{
                Write-Warning "Well not defined in $($Name)!"
                return $false
            }
        }
        Write-Host "All files listed in $($Name) are present in $($folder)!"
        # Format-Table -InputObject $filelist | Out-String | Write-Host
        return $true
    }

    [void] MoveBlob([object] $blob, [string] $NewName) {
        try{
            $result = ($blob | Copy-AzStorageBlob -DestContainer $this.ContainerName -DestBlob $NewName -Force)
            if(-not $result) {
                Write-Warning "Error moving blob $($blob.Name) to $($NewName)"
            }
            else {
                # remove the original file if the copy was successful
                $blob | Remove-AzStorageBlob -Force
            }
        }
        catch{
            Write-Warning "Error moving blob $($blob.Name) to $($NewName)"
        }
    }

    [bool] MoveToProcessing([string] $Name) {
        $folder = Split-Path $Name -Parent

        # gets all the files in the folder
        try{
            $files = $this.GetAzureStorageFilesFromFolder($folder)
            foreach($file in $files){
                $newFile=$file.Name.Replace("upload/", "processing/")
                Write-Host "Moving $($file.Name) to $($newFile)"
                $this.MoveBlob($file, $newFile)
            }    
            return $true
        }
        catch{
            Write-Warning "Error moving files in $($folder)"
            return $false
        }

        # for DATALAKE you may use this method
        #Move-AzDataLakeGen2Item -Context $ctx -FileSystem $filesystemName -Path $dirname -DestFileSystem $filesystemName -DestPath $dirname2
    }
}
