
# Azure CLI

To deploy via Azure Cloud Shell, connect via the Azure Portal or directly to [https://shell.azure.com/](https://shell.azure.com/).

- Login to the Azure Cloud Shell, and execute the following commands in the Azure Cloud Shell:

```text
az bicep upgrade
git clone https://github.com/benoitbMTL/fortiweb-azure-demo.git
cd fortiweb-azure-demo
```

- Create a resource group for your deployment

```text
az group create --location (location) --name (resourceGroupName)
```

- Deploy the templates

```text
 az deployment group create --name (deploymentName) --resource-group (resourceGroupName) --template-file 000-main.bicep
```

The script will ask you a few questions to bootstrap a full deployment.

After deployment you can output the important values such as public IP addresses, etc that you'll need to connect to your deployment.

```text
az deployment group show -g (resourceGroupName) -n (deploymentName) --query properties.outputs
```

# Deleting the Deployment

```text
az deployment group delete -g (resourceGroupName) -n (deploymentName)
```

# Example

```bicep
cd
rm -rf fortiweb-azure-demo
az bicep upgrade
git clone https://github.com/benoitbMTL/fortiweb-azure-demo.git
cd fortiweb-azure-demo
az group create --location canadaeast --name benoitbABPRessourceGroup
az deployment group create --name fortiweb-azure-demo --resource-group benoitbABPRessourceGroup --template-file 000-main.bicep
```

```bicep
az deployment group show -g benoitbABPRessourceGroup -n fortiweb-azure-demo --query properties.outputs
```