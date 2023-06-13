/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          PARAMETERS                                                             //  
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param location string
param deploymentPrefix string
param vnetNewOrExisting string
param vnetName string
param vnetAddressPrefix string
param subnet1Name string
param subnet1Prefix string
param subnet2Name string
param subnet2Prefix string
param subnet3Name string
param subnet3Prefix string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          VARIABLES                                                              // 
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var var_vnet_Name = ((vnetName == '') ? '${deploymentPrefix}-vnet' : vnetName)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          RESOURCES                                                              // 
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-04-01' = if (vnetNewOrExisting == 'new') {
    name: var_vnet_Name
    location: location
    properties: {
      addressSpace: {
        addressPrefixes: [
          vnetAddressPrefix
        ]
      }
      subnets: [
        {
          name: subnet1Name
          properties: {
            addressPrefix: subnet1Prefix
          }
        }
        {
          name: subnet2Name
          properties: {
            addressPrefix: subnet2Prefix
          }
        }
        {
          name: subnet3Name
          properties: {
            addressPrefix: subnet3Prefix
          }
        }
      ]
    }
  }

