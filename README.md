# YAML Pipeline Configuration

This document provides an annotated version of two YAML pipeline configurations. Each section is explained with inline comments to help understand the pipeline structure and functionality.

## 05-azure-kubernetes-cluster-iaac-pipeline.yml

This pipeline is used to manage the infrastructure for a Kubernetes cluster in Azure using Terraform.

```yaml
# Define the branches that trigger the pipeline
trigger:
- main # The pipeline runs when there are changes in the 'main' branch.

# Define the virtual machine image for the build agent
pool:
  vmImage: ubuntu-latest # Use the latest version of Ubuntu for the build agent.

# Steps in the pipeline
steps:
- script: echo K8S Terraform Azure!
  displayName: 'Run a one-line script'
  # A simple script step that prints "K8S Terraform Azure!" to the console.

- task: DownloadSecureFile@1
  name: publickey
  inputs:
    secureFile: 'azure_rsa.pub'
  # Download a secure file (e.g., SSH public key) for use in the pipeline.

- task: TerraformCLI@2
  displayName: 'Terraform Init'
  inputs:
    command: 'init'
    workingDirectory: '$(System.DefaultWorkingDirectory)/configuration/iaac/azure/kubernetes'
    backendType: 'azurerm'
    backendServiceArm: 'azure-resource-mananger-service-connection'
    backendAzureRmSubscriptionId: 'a755c4aa-edd0-4c67-83d9-bc7adc18bb18'
    ensureBackend: true
    backendAzureRmResourceGroupName: 'terraform-backend-rg'
    backendAzureRmResourceGroupLocation: 'westeurope'
    backendAzureRmStorageAccountName: 'storageaccountesherrott'
    backendAzureRmContainerName: 'storageaccountesherrottcontainer'
    backendAzureRmKey: 'kubernetes-dev.tfstate'
    allowTelemetryCollection: true
  # Initialise Terraform using an Azure backend to store the state file.

- task: TerraformCLI@2
  displayName: 'Terraform Apply'
  inputs:
    command: 'apply'
    workingDirectory: '$(System.DefaultWorkingDirectory)/configuration/iaac/azure/kubernetes'
    environmentServiceName: 'azure-resource-mananger-service-connection'
    commandOptions: '-var client_id=$(client_id) -var client_secret=$(client_secret) -var ssh_public_key=$(publickey.secureFilePath)'
    allowTelemetryCollection: true
  # Apply the Terraform configuration to create or update the Kubernetes cluster.
```

## 06-azure-kubernetes-code-ci-cd.yml

This pipeline is used for continuous integration and continuous deployment (CI/CD) of a Docker application to a Kubernetes cluster.

```yaml
# Define the branches that trigger the pipeline
trigger:
- main # The pipeline runs when there are changes in the 'main' branch.

# Define the virtual machine image for the build agent
pool:
  vmImage: ubuntu-latest # Use the latest version of Ubuntu for the build agent.

# Define the repository and variables used in the pipeline
resources:
- repo: self # Refers to the current repository.

variables:
  tag: '$(Build.BuildId)'
  # A variable that holds the build ID, used as a tag for Docker images.

# Define the stages of the pipeline
stages:
- stage: Build
  displayName: Build Docker Image & Publish K8S Files
  # The 'Build' stage, responsible for building the Docker image and preparing Kubernetes manifests.
  jobs:
  - job: Build
    displayName: Build Docker Image
    # The 'Build' job within the 'Build' stage.
    pool:
      vmImage: ubuntu-latest
    steps:
    - task: Docker@2
      displayName: Build Image
      inputs:
        containerRegistry: 'emilesherrott-docker-hub'
        repository: 'emilesherrott/currency-exchange-devops'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: '$(tag)'
      # Build and push the Docker image to the specified container registry.

    - task: CopyFiles@2
      inputs:
        SourceFolder: '$(System.DefaultWorkingDirectory)'
        Contents: '**/*.yaml'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'
      # Copy the Kubernetes YAML files to the staging directory.

    - task: PublishBuildArtifacts@1
      displayName: Publish K8S Files
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'manifests'
        publishLocation: 'Container'
      # Publish the Kubernetes YAML files as pipeline artifacts.

- stage: Deploy
  displayName: Deploy Image to K8S
  # The 'Deploy' stage, responsible for deploying the Docker image to the Kubernetes cluster.
  jobs:
  - job: Deploy
    displayName: Deploy Docker Image
    # The 'Deploy' job within the 'Deploy' stage.
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: DownloadPipelineArtifact@2
      inputs:
        buildType: 'current'
        artifactName: 'manifests'
        itemPattern: '**/*.yaml'
        targetPath: '$(System.ArtifactsDirectory)'
      # Download the previously published Kubernetes YAML files.

    - task: KubernetesManifest@1
      displayName: Deployment to K8S
      inputs:
        action: 'deploy'
        connectionType: 'kubernetesServiceConnection'
        kubernetesServiceConnection: 'azure-kubernetes-connection'
        namespace: 'default'
        manifests: '$(System.ArtifactsDirectory)/configuration/kubernetes/deployment.yaml'
        containers: 'emilesherrott/currency-exchange-devops:$(tag)'
      # Deploy the Docker image to the Kubernetes cluster using the downloaded YAML files.
```