/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          PARAMETERS                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param deploymentPrefix string
param location string
param adminUsername string
@secure()
param adminPassword string
param vnetNewOrExisting  string
param vnetName string
param subnet3Name string
param vnetResourceGroup string 
param subnet3Prefix string
param subnet3StartAddress string
param ubuntuSerialConsole string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          VARIABLES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//var vmName = '${deploymentPrefix}-ubuntu'
var vmName = 'ubuntu'

var vmNicName = '${deploymentPrefix}-ubuntu-NIC'
var vmNicId = ubuntuNic.id
var var_vnetName = ((vnetName == '') ? '${deploymentPrefix}-VNET' : vnetName)
var var_serialConsoleStorageAccountName = 'ubuntu${uniqueString(resourceGroup().id)}'
var serialConsoleStorageAccountType = 'Standard_LRS'
var serialConsoleEnabled = ((ubuntuSerialConsole == 'yes') ? true : false)
var subnet3Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet3Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet3Name))
var sn3IPArray = split(subnet3Prefix, '.')
var sn3IPArray2 = string(int(sn3IPArray[2]))
var sn3IPArray1 = string(int(sn3IPArray[1]))
var sn3IPArray0 = string(int(sn3IPArray[0]))
var sn3IPStartAddress = split(subnet3StartAddress, '.')
var sn3IPUbuntu = '${sn3IPArray0}.${sn3IPArray1}.${sn3IPArray2}.${int(sn3IPStartAddress[3])}'
var vmCustomDataBody = '''
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Wait for the repo 
echo "--> Waiting for repo to be reacheable"
curl --retry 20 -s -o /dev/null "https://download.docker.com/linux/centos/docker-ce.repo"
echo "--> Adding repository"
until dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
do
   dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
   sleep 2
done
dnf remove podman buildah
echo "--> Installing docker support and git"
until dnf -y install docker-ce docker-ce-cli containerd.io git
do
    dnf -y install docker-ce docker-ce-cli containerd.io git
    sleep 2
done
systemctl start docker.service
systemctl enable docker.service
# Wait for Internet access through by testing the docker registry
echo "Waiting for docker registry to be reacheable"
curl --retry 20 -s -o /dev/null "https://index.docker.io/v2/"
echo "--> installing dvwa docker container"
until docker run --restart unless-stopped --name dvwa -d -p 80:80 vulnerables/web-dvwa
do
    docker pull vulnerables/web-dvwa
    sleep 2
done
echo "--> installing fwb docker container"
until docker run -d --restart unless-stopped -p 1000:80 benoitbmtl/fwb
do 
    docker pull benoitbmtl/fwb
    sleep2
done
echo "--> installing web-app docker container"
git clone https://github.com/benoitbMTL/web-app.git /home/benoitb/web-app
docker build -t my-web-app /home/benoitb/web-app
docker run --restart unless-stopped -p 3000:3000 -d my-web-app
'''

var vmCustomData = base64(vmCustomDataBody)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          RESOURCES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource ubuntuNic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn3IPUbuntu
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet3Id
          }
        }
      }
    ]
  }
}


resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  plan: {
    name: '8-gen2'
    publisher: 'almalinux'
    product: 'almalinux'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_F2s_v2'
    }
    osProfile: {
      computerName: 'web'
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: vmCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: 'almalinux'
        offer: 'almalinux'
        sku: '8-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicId
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: serialConsoleEnabled
        storageUri: ((ubuntuSerialConsole == 'yes') ? reference(var_serialConsoleStorageAccountName, '2021-08-01').primaryEndpoints.blob : null)
      }
    }
  }
}

resource serialConsoleStorageAccountName 'Microsoft.Storage/storageAccounts@2021-02-01' = if (ubuntuSerialConsole == 'yes') {
  name: var_serialConsoleStorageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: serialConsoleStorageAccountType
  }
}

output ubuntuPrivateIP string = sn3IPUbuntu
