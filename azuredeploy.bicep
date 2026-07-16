// AzureBatch.L200.Troubleshooting.3 — one-click assessment environment.
//
// Deploying this template stands up the entire scenario automatically: a Batch
// account + Storage account, an AUTOSCALE pool, and a job with several tasks.
// The pool's autoscale formula scales one dedicated node per active task
// (capped at 10) even though each node has taskSlotsPerNode = 4. The result is
// gross over-provisioning: ~10 tasks cause ~10 nodes to be allocated when 3
// would suffice. No console app, no manual steps. The engineer's job is to
// explain why the pool allocates far more nodes than the workload requires.

@description('Prefix for generated resource names.')
param namePrefix string = 'batlab03'

@description('Azure region for all resources.')
param location string = resourceGroup().location

var suffix = uniqueString(resourceGroup().id)
var storageAccountName = toLower('${namePrefix}${suffix}')
var batchAccountName = toLower('${namePrefix}ba${suffix}')
var poolId = 'batch_assessment_03_pool'
var jobId = 'batch_assessment_03_job'
var contributorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

// Intentionally flawed autoscale formula: targets one node per active task
// (min 10) while each node can run 4 task slots -> over-provisioning.
var autoScaleFormula = '$samples = $ActiveTasks.GetSamplePercent(TimeInterval_Minute * 1); $tasks = $samples < 70 ? max(0,$ActiveTasks.GetSample(1)) : max( $ActiveTasks.GetSample(1), avg($ActiveTasks.GetSample(TimeInterval_Minute * 3))); $targetVMs = $tasks > 0 ? $tasks: max(0, $TargetDedicatedNodes / 2); $TargetDedicatedNodes = max(0, min($targetVMs, 10)); $NodeDeallocationOption = taskcompletion;'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: length(storageAccountName) > 24 ? substring(storageAccountName, 0, 24) : storageAccountName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource batch 'Microsoft.Batch/batchAccounts@2024-07-01' = {
  name: length(batchAccountName) > 24 ? substring(batchAccountName, 0, 24) : batchAccountName
  location: location
  properties: {
    autoStorage: {
      storageAccountId: storage.id
    }
    poolAllocationMode: 'BatchService'
    publicNetworkAccess: 'Enabled'
  }
}

resource pool 'Microsoft.Batch/batchAccounts/pools@2024-07-01' = {
  parent: batch
  name: poolId
  properties: {
    vmSize: 'STANDARD_D1_V2'
    taskSlotsPerNode: 4
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-datacenter'
          version: 'latest'
        }
        nodeAgentSkuId: 'batch.node.windows amd64'
      }
    }
    scaleSettings: {
      autoScale: {
        formula: autoScaleFormula
        evaluationInterval: 'PT5M'
      }
    }
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${namePrefix}-seed-id'
  location: location
}

resource batchContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(batch.id, uami.id, contributorRole)
  scope: batch
  properties: {
    roleDefinitionId: contributorRole
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Bash executed in an azure-cli container to create the job + tasks
// (jobs/tasks are Batch data-plane objects and cannot be declared in ARM).
var seedScript = '''
set -e
echo "Authenticating with managed identity..."
for a in 1 2 3 4 5 6; do
  az login --identity -u "$UAMI_CLIENT_ID" -o none && break
  echo "  az login retry $a"; sleep 15
done
echo "Logging in to Batch account (shared key)..."
for a in 1 2 3 4 5 6; do
  az batch account login -g "$RG" -n "$BATCH_NAME" --shared-key-auth -o none && break
  echo "  batch login retry $a (waiting for role propagation)"; sleep 20
done
echo "Creating job $JOB_ID..."
az batch job create --id "$JOB_ID" --pool-id "$POOL_ID" -o none
echo "Creating tasks..."
for i in $(seq 1 10); do
  az batch task create --job-id "$JOB_ID" --task-id "assessment_test_task_$i" --command-line "cmd /c echo Processing taskdata$i.txt & ping -n 900 127.0.0.1 >nul" -o none
  echo "  created assessment_test_task_$i"
done
echo "SEED_DONE"
'''

resource seed 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: '${namePrefix}-seed'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    sku: 'Standard'
    osType: 'Linux'
    restartPolicy: 'Never'
    containers: [
      {
        name: 'seed'
        properties: {
          image: 'mcr.microsoft.com/azure-cli:2.61.0'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: json('1.5')
            }
          }
          environmentVariables: [
            { name: 'UAMI_CLIENT_ID', value: uami.properties.clientId }
            { name: 'RG', value: resourceGroup().name }
            { name: 'BATCH_NAME', value: batch.name }
            { name: 'POOL_ID', value: poolId }
            { name: 'JOB_ID', value: jobId }
          ]
          command: [
            '/bin/bash'
            '-c'
            'echo ${base64(seedScript)} | base64 -d | tr -d \'\\r\' | bash'
          ]
        }
      }
    ]
  }
  dependsOn: [
    pool
    batchContributor
  ]
}

output batchAccountName string = batch.name
output batchAccountUrl string = 'https://${batch.properties.accountEndpoint}'
output storageAccountName string = storage.name
output poolId string = poolId
output jobId string = jobId
