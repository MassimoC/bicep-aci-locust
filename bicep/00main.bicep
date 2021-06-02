
// 01 : create storage account, fileshare, user assigned managed identity, copy python script to fileshare
// 02 : create master node
// 03 : create N worker nodes

// limit the required parms as much as possible
/*
  az deployment group create 
     -f ./00main.bicep 
     -g $rgname 
     -p appId=pao 
     -p targetHost=lnl-webfront-afd.azurefd.net
*/

/*
------------------------
parameters
------------------------
*/
@description('Identify the target environment. Default: dev')
@minLength(1)
@maxLength(3)
param environment string = 'dev'

@description('Application Identifier.')
@minLength(1)
@maxLength(3)
param appId string

@description('Hostname of the loadtest target.')
param targetHost string

@description('Number of Locust workers. Default: 3')
param nrOfWorkers int = 4

@description('Whether to randomize the location of the workers. Default: true')
param randomizeLocation bool = true

/*
------------------------
variables
------------------------
*/

var azlocations = [
  'francecentral'
  'japaneast'
  'eastus2'
  'westeurope'
  'northeurope'
  'westus'
  'australiaeast'
  'southcentralus'
  'japaneast'
  'southindia'
  'brazilsouth'
  'germanywestcentral'
  'uksouth'
  'canadacentral'
  'eastus2'
  'uaenorth'
  'francecentral'
  'japaneast'
  'eastus2'
  'westeurope'
  'northeurope'
  'westus'
  'australiaeast'
  'southcentralus'
  'japaneast'
  'southindia'
  'brazilsouth'
  'germanywestcentral'
  'uksouth'
  'canadacentral'
  'eastus2'
  'uaenorth'  
]



/*
------------------------------------------------
STORAGE ACCOUNT
------------------------------------------------
*/

module storage './01storage.bicep' = {
  name: 'storage-config'
  params: {
    environment: environment
    appId: appId
  }
}

// assign outputs to variables
var storageAccountName =  storage.outputs.accountName

/*
------------------------------------------------
ACI : LOCUST MASTER NODE
------------------------------------------------
*/

module locustmaster './02acimaster.bicep' = {
  name: 'locust-master-config'
  params: {
    environment: environment
    appId: appId
    storageAccountName:storageAccountName
    host:targetHost
  }
}

var masterHost = locustmaster.outputs.masterFqdn

/*
------------------------------------------------
ACI : WORKER NODES
------------------------------------------------
*/

module locustworker './03aciworker.bicep' = [for i in range(0,nrOfWorkers): {
  name: 'locust-worker-config-${i}'
  params: {
    environment: environment
    appId: appId
    storageAccountName:storageAccountName
    masterHost:masterHost
    instanceIndex: i
    location: randomizeLocation ? azlocations[i] : resourceGroup().location
  }
}]
