/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//  https://shell.azure.com                                                                                                        //
//                                                                                                                                 //
//  Deployment Commands:                                                                                                           //
//  az group create --location <location> --name <resourceGroupName>                                                               //
//  az deployment group create --name <deploymentName> --resource-group <resourceGroupName> --template-file 000-main.bicep         //
//  az deployment group show -g <resourceGroupName> -n <deploymentName> --query properties.outputs                                 //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters impact which Modules are Deployed                                                                     //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description ('Do you want to deploy a FortiWeb as a part of this Template (Y/N)')
param deployFortiWeb string = 'yes'

@description ('Do you want to deploy a ubuntu Instance as a part of this Template (Y/N)')
param deployUbuntu string = 'yes'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//  The Following Parameters will be asked in the form of a prompt                                                                 //
//  when running main.bicep via AZ CLI (az deployment group create)                                                                //
//                                                                                                                                 //
//   NOTES:                                                                                                                        // 
//   1). The Deployment Prefix will be used throughout the deployment                                                              //
//   2). The same Username and Password will be applied to FortiWeb and Ubuntu VMs                                                   //
//       and can be changed post-deployment                                                                                        //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Username for the FortiWeb VM')
param adminUsername string = 'benoitb'

@description('Password for the FortiWeb VM')
@secure()
param adminPassword string

@description('Naming prefix for all deployed resources.')
param deploymentPrefix string = 'fwb'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values used globally                                                             //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param location string = resourceGroup().location

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the Network Template                               //
//                                                                                                                                 //
//                                                                                                                          123    //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Identify whether to use a new or existing vnet')
param vnetNewOrExisting string = 'new'

@description('Name of the Azure virtual network, required if utilizing and existing VNET. If no name is provided the default name will be the Resource Group Name as the Prefix and \'-VNET\' as the suffix')
param vnetName string = 'fwb-vnet-demo'

@description('Resource Group containing the existing virtual network, leave blank if a new VNET is being utilized')
param vnetResourceGroup string = 'fwb-cse-demo'

@description('Virtual Network Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet 1 Name')
param subnet1Name string = 'frontend'

@description('Subnet 1 Prefix')
param subnet1Prefix string = '10.0.1.0/24'

@description('Subnet 1 start address, 2 consecutive private IPs are required')
param subnet1StartAddress string = '10.0.1.10'

@description('Subnet 2 Name')
param subnet2Name string = 'backend'

@description('Subnet 2 Prefix')
param subnet2Prefix string = '10.0.2.0/24'

@description('Subnet 2 start address, 2 consecutive private IPs are required')
param subnet2StartAddress string = '10.0.2.10'

@description('Subnet 3 Name')
param subnet3Name string = 'protected'

@description('Subnet 3 Prefix')
param subnet3Prefix string = '10.0.3.0/24'

@description('Subnet 3 start address, 2 consecutive private IPs are required')
param subnet3StartAddress string = '10.0.3.10'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the FortiWeb Template                              //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('FortiWeb VM Name')
param fortiWebVmName string = 'fwb01'

@description('Identifies whether to to use PAYG or BYOL license model')
@allowed([
  'fortinet_fw-vm'
  'fortinet_fw-vm_payg_v2'
])
param fortiWebImageSKU string = 'fortinet_fw-vm'

@description('FortiWeb versions available in the Azure Marketplace. Additional version can be downloaded via https://support.fortinet.com/')
@allowed([
  '6.3.17'
  '7.0.0'
  '7.0.3'
  '7.2.0'
  'latest'
])
param fortiWebImageVersion string = 'latest'

@description('Virtual Machine size selection - must be F4 or other instance that supports 4 NICs')
@allowed([
  'Standard_F2s'
  'Standard_F4s'
  'Standard_F8s'
  'Standard_F16s'
  'Standard_F2'
  'Standard_F4'
  'Standard_F8'
  'Standard_F16'
  'Standard_F2s_v2'
  'Standard_F4s_v2'
  'Standard_F8s_v2'
  'Standard_F16s_v2'
  'Standard_F32s_v2'
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D2_v4'
  'Standard_D4_v4'
  'Standard_D8_v4'
  'Standard_D16_v4'
  'Standard_D32_v4'
  'Standard_D2s_v4'
  'Standard_D4s_v4'
  'Standard_D8s_v4'
  'Standard_D16s_v4'
  'Standard_D32s_v4'
  'Standard_D2a_v4'
  'Standard_D4a_v4'
  'Standard_D8a_v4'
  'Standard_D16a_v4'
  'Standard_D32a_v4'
  'Standard_D2as_v4'
  'Standard_D4as_v4'
  'Standard_D8as_v4'
  'Standard_D16as_v4'
  'Standard_D32as_v4'
  'Standard_D2_v5'
  'Standard_D4_v5'
  'Standard_D8_v5'
  'Standard_D16_v5'
  'Standard_D32_v5'
  'Standard_D2s_v5'
  'Standard_D4s_v5'
  'Standard_D8s_v5'
  'Standard_D16s_v5'
  'Standard_D32s_v5'
  'Standard_D2as_v5'
  'Standard_D4as_v5'
  'Standard_D8as_v5'
  'Standard_D16as_v5'
  'Standard_D32as_v5'
  'Standard_D2ads_v5'
  'Standard_D4ads_v5'
  'Standard_D8ads_v5'
  'Standard_D16ads_v5'
  'Standard_D32ads_v5'
])
param instanceType string = 'Standard_F4s'

@description('Accelerated Networking enables direct connection between the VM and network card. Only available on 2 CPU F/Fs and 4 CPU D/Dsv2, D/Dsv3, E/Esv3, Fsv2, Lsv2, Ms/Mms and Ms/Mmsv2')
@allowed([
  false
  true
])
param acceleratedNetworking bool = true

@description('The ARM template provides a basic configuration. Additional configuration can be added here.')
param fortiWebAdditionalCustomData string = ''

@description('Public IP for the FortiWeb VM')
@allowed([
  'new'
  'existing'
  'none'
])
param publicIPNewOrExistingOrNone string = 'new'

@description('Name of Public IP address element.')
param publicIPName string = 'fwb-demo-public-ip'

@description('Resource group to which the Public IP belongs.')
param publicIPResourceGroup string = 'fwb-cse-demo'

@description('Type of public IP address')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPType string = 'Static'

@description('Enable Serial Console on the FortiWeb')
@allowed([
  'yes'
  'no'
])
param fwbserialConsole string = 'yes'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Parameters are STATIC and their values will be pushed down to the ubuntu Template                                  //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@description('Enable Serial Console on the Ubuntu')
param ubuntuSerialConsole string = 'yes'

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  The Following Modules are Responsible for the Deployment the Network and FortiWeb Bicep Files.                                 //
//  These values should NOT be modified.                                                                                           //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module networkTemplate '001-network.bicep' = {
  name: 'networkDeployment'
  params: {
    deploymentPrefix: deploymentPrefix
    location: location
    subnet1Name: subnet1Name
    subnet1Prefix: subnet1Prefix
    subnet2Name: subnet2Name
    subnet2Prefix: subnet2Prefix
    subnet3Name: subnet3Name
    subnet3Prefix: subnet3Prefix
    vnetAddressPrefix: vnetAddressPrefix
    vnetName: vnetName
    vnetNewOrExisting: vnetNewOrExisting
      }
}

module fortiWebTemplate '002-fortiweb.bicep' = if (deployFortiWeb == 'yes') {
  name: 'fortiwebDeployment'
  params: {
    fortiWebVmName: fortiWebVmName
    adminPassword: adminPassword
    adminUsername: adminUsername
    deploymentPrefix: deploymentPrefix
    fortiWebAdditionalCustomData:fortiWebAdditionalCustomData
    fortiWebImageSKU: fortiWebImageSKU
    fortiWebImageVersion: fortiWebImageVersion
    fwbserialConsole: fwbserialConsole
    acceleratedNetworking: acceleratedNetworking
    instanceType: instanceType
    location: location
    publicIPName: publicIPName
    publicIPNewOrExistingOrNone: publicIPNewOrExistingOrNone
    publicIPResourceGroup: publicIPResourceGroup
    publicIPType: publicIPType
    subnet1Name: subnet1Name
    subnet2Name: subnet2Name
    subnet1StartAddress: subnet1StartAddress
    subnet2StartAddress: subnet2StartAddress
    subnet3StartAddress: subnet3StartAddress
    vnetName:vnetName 
    vnetNewOrExisting: vnetNewOrExisting
    vnetResourceGroup: vnetResourceGroup
     }
  dependsOn: [
    networkTemplate
  ]
}

module ubuntuTemplate '003-ubuntu.bicep' = if (deployUbuntu == 'yes') {
  name: 'ubuntuDeployment'
  params: {
    adminPassword: adminPassword
    adminUsername:  adminUsername
    deploymentPrefix: deploymentPrefix 
    location: location
    subnet3Name: subnet3Name
    subnet3Prefix: subnet3Prefix
    subnet3StartAddress: subnet3StartAddress
    vnetName: vnetName
    vnetNewOrExisting: vnetNewOrExisting
    vnetResourceGroup: vnetResourceGroup
    ubuntuSerialConsole: ubuntuSerialConsole
  }
  dependsOn: [
    fortiWebTemplate
  ]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                      The following portion of the template is responsible for Output generation                                 //
//                      To Output these Values please Run:                                                                         //
//                                                                                                                                 //
//                      az deployment group show -g <resourceGroupName> -n <deploymentName> --query properties.outputs             //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output fortiWebManagementConsole string = 'https://${fortiWebTemplate.outputs.fortiWebPublicIP}:8443'
output ubuntuHTTP string = 'http://${fortiWebTemplate.outputs.fortiWebPublicIP}:80'
