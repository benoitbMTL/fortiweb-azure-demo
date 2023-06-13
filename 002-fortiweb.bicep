/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          PARAMETERS                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param adminUsername string
@secure()
param adminPassword string
param deploymentPrefix string
param fortiWebImageSKU string
param fortiWebImageVersion string
param fortiWebAdditionalCustomData string
param instanceType string
param acceleratedNetworking bool
param publicIPNewOrExistingOrNone string
param publicIPName string
param publicIPResourceGroup string
param publicIPType string
param vnetNewOrExisting string
param vnetName string
param vnetResourceGroup string
param subnet1Name string 
param subnet1Prefix string
param subnet1StartAddress string
param subnet2Name string
param subnet2Prefix string
param subnet2StartAddress string
param fwbserialConsole string
@secure()
param location string
param fortinetTags object
param vnetAddressPrefix string
param subnet3StartAddress string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          VARIABLES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var imagePublisher = 'fortinet'
var imageOffer = 'fortinet_fortiweb-vm_v5'
var var_vnetName = ((vnetName == '') ? '${deploymentPrefix}-VNET' : vnetName)
var subnet1Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet1Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet1Name))
var subnet2Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet2Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet2Name))
var fwbGlobalDataBody = 'config system settings\n set enable-file-upload enable\n end\nconfig system admin\nedit admin\nset password Q1w2e34567890--\nend\n'
var fwbCustomDataBody = '${fwbGlobalDataBody}${fwbCustomDataPreconfig}${fortiWebAdditionalCustomData}\n'
var fwbCustomDataCombined = { 
  'cloud-initd' : 'enable'
  'usr-cli': fwbCustomDataBody
  }
var fwbCustomDataPreconfig = '${fwbCustomDataVIP}${fwbServerPool}${letsEncrypt}${bulkPoCConfig}'
var fwbCustomDataVIP = '\nconfig system vip\n edit "DVWA_VIP"\n set vip ${reference(publicIPId).ipAddress}/32\n set interface port1\n next\n end\n'
var fwbStaticRoute = '\nconfig router static\n edit 1\n set dst ${vnetAddressPrefix}\n set gateway ${sn2GatewayIP}\n set device port2\n next\n end\n'
var fwbServerPool = '\nconfig server-policy server-pool\n edit "DVWA_POOL"\n config pserver-list\n edit 1\n set ip ${subnet7StartAddress}\n next\n end\n next\n end\n'
var letsEncrypt = '\nconfig system certificate letsencrypt\nedit "DVWA_LE_CERTIFICATE"\nset domain ${deploymentPrefix}.${location}.cloudapp.azure.com\nset validation-method TLS-ALPN\nnext\nend\n'
var wvsProfile = '\nconfig wvs profile\nedit "DVWASCANPROFILE"\nset scan-target https://${sn1IPfwb}\nset scan-template "OWASP Top 10"\nset custom-header0 "Cookie: security=low; PHPSESSID=XXXXXXXXXXXXXXXXXXXX"\nset form-based-authentication enable\nset form-based-username pablo\nset form-based-password letmein\nset form-based-auth-url https://${sn1IPfwb}/login.php\nset username-field username\nset password-field password\nset session-check-url https://10.0.5.5/index.php\nset session-check-string Welcome\nset data-format %u=%U&%p=%P\nnext\nend\n'
var bulkPoCConfig = loadTextContent('005-fortiwebCustomData.txt')

var fwbCustomData = base64(string(fwbCustomDataCombined))
var var_fwbNic1Name = '${var_fwbVmName}-Nic1'
var fwbNic1Id = fwbNic1Name.id
var var_fwbNic2Name = '${var_fwbVmName}-Nic2'
var fwbNic2Id = fwbNic2Name.id
var var_serialConsoleStorageAccountName = 'fwbsc${uniqueString(resourceGroup().id)}'
var serialConsoleStorageAccountType = 'Standard_LRS'
var serialConsoleEnabled = ((fwbserialConsole == 'yes') ? true : false)
var var_publicIPName = ((publicIPName == '') ? '${deploymentPrefix}-FWB-PIP' : publicIPName)
var publicIPId = ((publicIPNewOrExistingOrNone == 'new') ? publicIPName_resource.id : resourceId(publicIPResourceGroup, 'Microsoft.Network/publicIPAddresses', var_publicIPName))
var publicIPAddressId = {
  id: publicIPId
}
var ilbProperties = {
  properties: {
    privateIPAddress: sn1IPlb
    privateIPAllocationMethod: 'Static'
    subnet: subnet5Id
  }
}
var elbProperties = {
  properties: {
    publicIPAddress: publicIPAddressId
  }
}
var var_NSGName = '${deploymentPrefix}-${uniqueString(resourceGroup().id)}-NSG'
var NSGId = NSGName.id
var sn1IPArray = split(subnet5Prefix, '.')
var sn1IPArray2 = string(int(sn1IPArray[2]))
var sn1IPArray1 = string(int(sn1IPArray[1]))
var sn1IPArray0 = string(int(sn1IPArray[0]))
var sn1IPStartAddress = split(subnet5StartAddress, '.')
var sn1IPfwb = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${int(sn1IPStartAddress[3])}'
var sn1IPlb = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${(int(sn1IPStartAddress[3]) - 1)}'
var sn2IPArray = split(subnet6Prefix, '.')
var sn2IPArray2 = string(int(sn2IPArray[2]))
var sn2IPArray1 = string(int(sn2IPArray[1]))
var sn2IPArray0 = string(int(sn2IPArray[0]))
var sn2IPStartAddress = split(subnet6StartAddress, '.')
var sn2GatewayIP = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${sn2IPArray3}'
var sn2IPArray3 = string((int(sn2IPArray2nd[0]) + 1))
var sn2IPArray2nd = split(sn2IPArray2ndString, '/')
var sn2IPArray2ndString = string(sn2IPArray[3])
var sn2IPfwb = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${(int(sn2IPStartAddress[3]) + 1)}'


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          RESOURCES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource serialConsoleStorageAccountName 'Microsoft.Storage/storageAccounts@2021-02-01' = if (fwbserialConsole == 'yes') {
  name: var_serialConsoleStorageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: serialConsoleStorageAccountType
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2021-07-01' = if (!useAZ) {
  name: var_availabilitySetName
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource NSGName 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_NSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSHInbound'
        properties: {
          description: 'Allow SSH In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          description: 'Allow 80 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPSInbound'
        properties: {
          description: 'Allow 443 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowDevRegInbound'
        properties: {
          description: 'Allow 514 in for device registration'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '514'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowMgmtHTTPInbound'
        properties: {
          description: 'Allow 8080 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowMgmtHTTPSInbound'
        properties: {
          description: 'Allow 8443 In'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutbound'
        properties: {
          description: 'Allow all out'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource publicIPName_resource 'Microsoft.Network/publicIPAddresses@2022-05-01' = if (publicIPNewOrExistingOrNone == 'new') {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: publicIPType
    dnsSettings: {
      domainNameLabel: toLower(deploymentPrefix)
    }
  }
}



resource fwbNic1Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbNic1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn1IPfwb
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet1Id
          }
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: NSGId
    }
  }
}

resource fwbNic2Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbNic2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: sn2IPfwb
          subnet: {
            id: subnet2Id
          }
        }
      }
    ]
    enableIPForwarding: false
    enableAcceleratedNetworking: acceleratedNetworking
  }
}

resource fwbBNic2Name 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbBNic2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: sn2IPfwbB
          subnet: {
            id: subnet2Id
          }
        }
      }
    ]
    enableIPForwarding: false
    enableAcceleratedNetworking: acceleratedNetworking
  }
}

resource fwbVmName 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  name: var_fwbVmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: fortiWebImageSKU
    publisher: imagePublisher
    product: imageOffer
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceType
    }
    osProfile: {
      computerName: var_fwbVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: fwbCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: fortiWebImageSKU
        version: fortiWebImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: fwbNic1Id
        }
        {
          properties: {
            primary: false
          }
          id: fwbNic2Id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: serialConsoleEnabled
        storageUri: ((fwbserialConsole == 'yes') ? reference(var_serialConsoleStorageAccountName, '2021-08-01').primaryEndpoints.blob : null)
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          OUTPUTS                                                                //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output fortiWebPublicIP string = ((publicIPNewOrExistingOrNone == 'new') ? reference(publicIPId).dnsSettings.fqdn : '')
output fwbCustomData string = fwbCustomData
output fwbCustomDataPreconfig string = fwbCustomDataPreconfig
