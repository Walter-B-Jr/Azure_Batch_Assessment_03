## Lab Name: AzureBatch.L200.Troubleshooting.3

### Introduction
This is a Level 200 lab for Troubleshooting in Azure Batch. It is a **self-contained failure scenario**: deploying the template stands up the entire environment *and* runs the failing workload automatically. There is **no console app to build or run** and **no manual steps** to trigger the issue — your job is to diagnose it and correct the misconfiguration.

## Deployment Instructions

Deploy the ARM template **`azuredeploy.json`** (root of this repo) using any option below.

### Option 1 - Deploy to Azure (one-click)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWalter-B-Jr%2FAzure_Batch_Assessment_03%2Fmaster%2Fazuredeploy.json)

Click the button, pick (or create) a resource group + region, optionally set `namePrefix`, then **Review + create** -> **Create**.

### Option 2 - Azure CLI
```powershell
az group create -n rg-batch-lab-03 -l eastus2
az deployment group create -g rg-batch-lab-03 --template-file azuredeploy.json --parameters namePrefix=batlab03
```
> Pick a region where your subscription has Batch **dedicated core quota** (the pool can scale up to 10 nodes).

### Option 3 - Azure Portal (Load file)
1. Portal -> search **Deploy a custom template** -> **Build your own template in the editor**.
2. **Load file** -> select `azuredeploy.json` -> **Save**.
3. Choose/create a resource group + region, optionally set `namePrefix`, then **Review + create** -> **Create**.

## What happens automatically
The deployment creates the Batch and Storage accounts, an **autoscale** pool, and (via a short-lived seed container) a job with ~10 tasks. When the pool's autoscale formula is next evaluated (roughly every 5 minutes) it will begin scaling out. Allow a few minutes after deployment before reviewing the pool's node count and autoscale evaluation results.

## Resources Created
- A Resource Group
- A Batch Account
- A Storage Account
- A Batch **Pool** with autoscale enabled (`batch_assessment_03_pool`, `taskSlotsPerNode = 4`)
- A Batch **Job** + **Tasks** (`batch_assessment_03_job`)
- A short-lived User-Assigned Managed Identity + Container Instance used only to seed the job/tasks

## Scenario
In this lab, the Batch Job is already running. You will notice that the pool scales to **10 nodes**. What we want is for the autoscale formula to take **`MaxTasksPerComputeNode`** into account. The pool is configured so each node can handle **4 tasks**, so the desired outcome is a total of **3 nodes** running (4 tasks on each node).

## Your Goal
Your goal is to modify the autoscale formula so that it accounts for the **`MaxTasksPerComputeNode`** (task slots per node) value, resulting in efficient allocation (3 nodes for ~10 tasks instead of 10).

## Proof of Solution
1. Take a screenshot of the pool scaling up toward **10 nodes** with the original formula (and/or the pool's **autoscale evaluation result** showing `$TargetDedicatedNodes` = number of tasks).
2. Correct the pool's **autoscale formula** so it divides the active-task count by the task slots per node. Review the following for guidance: https://docs.microsoft.com/en-us/azure/batch/batch-automatic-scaling#write-an-autoscale-formula
   - You can update the formula on the pool directly (Azure Portal -> Batch account -> Pools -> Scale) or by editing and redeploying the template.
3. After the corrected formula evaluates, the pool should allocate only **3 nodes**. Take a screenshot of the three nodes being allocated, and a screenshot of the corrected autoscale formula on the pool.

## Important: After completing the lab
Please make sure to delete all the resources you created for this lab.
