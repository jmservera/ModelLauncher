# Model Launcher

An Azure Function example to watch a storage account for new files and launch a container instance to process them. In this example we are polling the
Azure Storage for changes, because [Event Grid](https://docs.microsoft.com/azure/event-grid/overview) still [does not support private endpoints for System Topics](https://learn.microsoft.com/azure/event-grid/configure-private-endpoints).

## Requirements

* Azure Functions Host v4 with Powershell 7.2 in Linux:
```json
    "FUNCTIONS_WORKER_RUNTIME": "powershell",
    "FUNCTIONS_WORKER_RUNTIME_VERSION": "7.2"
```
* Azure Storage Account
* Azure Container Registry

## Configuration

Add these variables to your environment:

```json
    "AzureAccountName": "account name for the azure storage",
    "AzureAccountKey": "key for the storage account, you can remove this if you use a managed identity",
    "ContainerName": "name of the container",
    "ResourceGroupName":"name of the resource group where the container instance will be created"
```

Add a System Managed Identity to this Function App and assign the minimal permissions that allows the 
identity to create new Container Instances in the Resource Group, and if you don't want to provide a Storage Key you can also provide the *Storage Blob Data Contributor* role to the 
function app identity in the storage account.

## Disclaimer

This code is not production ready, it's just an example to show how to use Azure Functions to launch container instances. You still need to provide:

* Proper logging and error handling: there's some logging in the code, but not all error cases
are handled.
* Reliability: the container instance may fail and there's no retry logic for it in this code. Furthermore, there's nothing that prevents this code to restart the instance while it is running. It would be probably a better idea to create a queue with the jobs and have a separate function to process them, or use a Durable Function.
* Cleanup: the container instance is not deleted after it finishes, you may need another function that lists the containers from time to time and deletes old instances.

## Additional enhancements

* Atomicity: when you have multiple files in a folder, this code is moving them one by one to the *processing* folder. It is possible to move them all at once activating the hierarchical namespace and renaming the folder, but you will need to use a different API.
* Speedup: the container instance is created each time, but if you are running it in a standard plan you may have the container always running and just run a [command inside it](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-exec).

