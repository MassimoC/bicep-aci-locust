/*
------------------------
parameters
------------------------
*/
@description('Identify the target environment.')
@minLength(1)
@maxLength(3)
param environment string = 'dev'

@description('Application Identifier.')
@minLength(1)
@maxLength(3)
param appId string

@description('Storage account name. Where to locate the commands to be executed.')
param storageAccountName string

@description('Storage share name.')
param fileShareName string = 'locust'

@description('Hostname of the locust master node')
param masterHost string

@description('Index of the worker instance')
param instanceIndex int

@description('Location of the worker.')
param location string = resourceGroup().location

/*
------------------------
global variables
------------------------
*/
var aciNameWorker = toLower('${appId}-${environment}-locust-worker-${instanceIndex}')
var image = 'locustio/locust:1.5.3'
var cpuCores = 1
var memoryInGb = 2
var containerName = 'locust'
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', storageAccountName)

/*
------------------------
resources
------------------------
*/

resource workerContainerGroupName 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: aciNameWorker
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: image
          environmentVariables: []
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          ports: [
            {
              port: 8089
            }
            {
              port: 5557
            }
          ]
          command: [
            'locust'
            '--locustfile'
            '/home/locust/locust/locustfile.py'
            '--worker'
            '--master-host'
            '${masterHost}'
          ]
          volumeMounts: [
            {
              mountPath: '/home/locust/locust/'
              name: 'locust'
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    volumes: [
      {
        name: containerName
        azureFile: {
          shareName: fileShareName
          storageAccountName: storageAccountName
          storageAccountKey: listKeys(storageAccountId, '2018-02-01').keys[0].value
        }
      }
    ]
  }
}
