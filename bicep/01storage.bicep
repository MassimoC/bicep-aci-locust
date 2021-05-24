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

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountSKU string = 'Standard_LRS'

/*
------------------------
global variables
------------------------
*/
var storageAccountName  = toLower('${appId}${environment}sto')
var userAssignedIdentityName = toLower('${appId}-${environment}-msi')
var roleAssignmentName = guid(resourceGroup().id, 'contributor')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var deploymentScriptName = toLower('${appId}-${environment}-pyconfig')
var filePath = 'locustfile.py'
var externalPath = 'https://raw.githubusercontent.com/MassimoC/bicep-aci-locust/main/locust/${filePath}'

/*
------------------------
resources
------------------------
*/
var fileShareName = 'locust'

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: storageAccountSKU
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: '${storage.name}/default/${fileShareName}'
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: resourceGroup().location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    arguments: '-rgName ${resourceGroup().name} -storageAccountName ${storage.name} -filePath ${filePath}'
    supportingScriptUris:[
      externalPath
    ]
    scriptContent: '''
      param([string] $rgName, [string] $storageAccountName, [string] $filePath)
      $ctx = Get-AzStorageAccount -ResourceGroupName $rgName -Name $storageAccountName
      $file = Get-Item $filePath
      Set-AzStorageFileContent -ShareName 'locust' -Source $file.FullName -Context $ctx.Context
      $DeploymentScriptOutputs = @{}
    '''    
    retentionInterval: 'P1D'
  }
  dependsOn: [
    roleAssignment
    fileShare
  ]
}

/*
------------------------
outputs
------------------------
*/
output accountName string = storageAccountName
