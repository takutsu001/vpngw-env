/*
------------------
param section
------------------
*/
// Common
param location string
param hubVNetName string
param spoke2VNetName string 
param spoke2VNetAddress string
// VM Subnet
param spoke2SubnetName1 string
param spoke2SubnetAddress1 string
// for VM
param spoke2vmName1 string
param vmSizeLinux string
@secure()
param adminUserName string
@secure()
param adminPassword string

/*
------------------
var section
------------------
*/
var spoke2Subnet1 = { 
  name: spoke2SubnetName1 
  properties: { 
    addressPrefix: spoke2SubnetAddress1
    networkSecurityGroup: {
      id: nsgDefault.id
    }
  } 
} 

/*
------------------
resource section
------------------
*/
// create network security group for spoke vnet
resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'spoke2-nsg'
  location: location
  properties: {
  //  securityRules: [
  //    {
  //     name: 'Allow-SSH'
  //      properties: {
  //      description: 'description'
  //      protocol: 'TCP'
  //      sourcePortRange: '*'
  //      destinationPortRange: '22'
  //      sourceAddressPrefix: myipaddress
  //      destinationAddressPrefix: '*'
  //      access: 'Allow'
  //      priority: 1000
  //      direction: 'Inbound'
  //    }
  //  }
  //]
  }
}

// create spokeVNet & spokeSubnet
resource spoke2VNet 'Microsoft.Network/virtualNetworks@2021-05-01' = { 
  name: spoke2VNetName 
  location: location 
  properties: { 
    addressSpace: { 
      addressPrefixes: [ 
        spoke2VNetAddress 
      ] 
    } 
    subnets: [ 
      spoke2Subnet1
    ] 
  } 
  // Get subnet information where VMs are connected.
  resource spoke2VMSubnet 'subnets' existing = {
    name: spoke2SubnetName1
  }
}

// Retrieves information about a resource (hubVNet) created in a separate Bicep file for VNet peering configuration.
resource hubVNet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: hubVNetName
}

// Virtual network peering between hub-VNet to spoke2-VNet
resource peeringHub2Spoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'hub-to-spoke2-peering'
  parent: hubVNet
  properties: {
    remoteVirtualNetwork: {
      id: spoke2VNet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: ['${spoke2VNet}']
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: ['${spoke2VNet}']
    }
  }
}

// Virtual network peering between spoke2-VNet to Hub-VNet
resource peeringspoke2hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'spoke2-to-hub-peering'
  parent: spoke2VNet
  properties: {
    remoteVirtualNetwork: {
      id: hubVNet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteAddressSpace: {
      addressPrefixes: ['${hubVNet}']
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: ['${hubVNet}']
    }
  }
}

// create VM in spoke2VNet
// create network interface for CentOS VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${spoke2vmName1}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spoke2VNet::spoke2VMSubnet.id
          }
        }
      }
    ]
  }
}

// create CentOS vm in spoke2 vnet
resource centosVM1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: spoke2vmName1
  location: location
  plan: {
    name: 'centos-8-0-free'
    publisher: 'cognosys'
    product: 'centos-8-0-free'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSizeLinux
    }
    osProfile: {
      computerName: spoke2vmName1
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'cognosys'
       offer: 'centos-8-0-free'
        sku: 'centos-8-0-free'
        version: 'latest'
      }
      osDisk: {
        name: '${spoke2vmName1}-disk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

/*
------------------
output section
------------------
*/
// return the private ip address of the vm to use from parent template
@description('return the private ip address of the vm to use from parent template')
output vmPrivateIp string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
