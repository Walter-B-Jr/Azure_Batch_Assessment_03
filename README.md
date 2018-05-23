## Lab Name: AzureBatch.L200.autoscale.3

## Introduction
This is a Level 200 lab for Autoscale in Azure Batch Service.
## Deployment Instructions
1.	Deploy the template and download the source code.
2.	Open up the application that was created in the deployment template to get the credentials required for the sample code to work correctly. Then, proceed to open the code sample in VS and make the following required changes:
a.	Open “Program.cs” under DotNetTutorial application. 
b.	Proceed to enter the credentials provided in the application to the code sample as shown below
i.	BatchAccountName
ii.	BatchAccountKey
iii.	BatchAccountUrl
iv.	StorageAccountName
v.	StorageAccountKey
vi.	You can name your PoolID and JobID however you desire.


This lab should take approximately 10 – 15 minutes to deploy to Azure.
## Resources Created
This lab creates the following resources.
-	Resource Group
-	Batch account
-	Storage Account
-	App Service application (which contains Batch and Storage account credentials)
## Scenario
In this lab, you will run the Batch Job. You will notice that the pool will scale to 10 nodes. What we desire is that the autoscale formula takes into account the “MaxTaskPerComputeNode” as well. So the current pool is configured to have each node handle 4 task. Modify the autoscale formula to account for the “MaxTaskPerComputeNode” value. The desired outcome is to have a total of 3 nodes running. (4 tasks running on each node).
## Your Goal
Your goal is to modify the Autoscale rule to take into account the “MaxTaskPerComputeNode” value. 
## Proof of Solution
1.	Take a screenshot of the 10 nodes created when you run the Job the first time. 
 
2.	Proceed to make changes to the sample code. (change the autoscale formula only). Review the following for guidance: https://docs.microsoft.com/en-us/azure/batch/batch-automatic-scaling#write-an-autoscale-formula...  
3.	First, you will need to delete the pool and Job in the Azure Portal. Rerun the sample code now that you have made the necessary changes. The proper result is that your pool should only spin up 3 nodes. Take a screenshot of the three nodes being allocated in the portal. 

Also, take a screenshot of the autoscale formula from the Pool as shown further below
 
 

## Important: After the completion of the lab:
Please make sure to delete all the resources you created for this lab. 
Leaving resources undeleted will incur an unnecessary cost to your cost center.  
