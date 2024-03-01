/*
------------------
param section
------------------
*/
// Common
param location string
param hubVNetName string 
param myipaddress string
param hubVNetAddress string
// VM Subnet
param hubSubnetName1 string
param hubSubnetAddress1 string
// VPN Gateway Subnet
param hubSubnetName2 string
param hubSubnetAddress2 string
// VPN Gateway Subnet
param hubSubnetName3 string
param hubSubnetAddress3 string
// for VM
param hubvmName1 string
param vmSizeLinux string
@secure()
param adminUserName string
@secure()
param adminPassword string
// for VPN Gateway
param hubVPNGWName string
param hubLngName string
param spoke1VNetAddress string
param spoke2VNetAddress string

/*
------------------
var section
------------------
*/
// VM Subnet
var hubSubnet1 = { 
  name: hubSubnetName1 
  properties: { 
    addressPrefix: hubSubnetAddress1
    networkSecurityGroup: {
    id: nsgDefault.id
    }
  }
}
// Firewall Subnet
var hubSubnet2 = { 
  name: hubSubnetName2 
  properties: { 
    addressPrefix: hubSubnetAddress2
  }
} 
// VPN Gateway Subnet
var hubSubnet3 = { 
  name: hubSubnetName3 
  properties: { 
    addressPrefix: hubSubnetAddress3
  } 
} 

/*
------------------
resource section
------------------
*/

// create network security group for hub vnet
resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'hub-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
        description: 'SSH access permission from your own PC.'
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: myipaddress
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 1000
        direction: 'Inbound'
      }
    }
  ]
}
}

// create hubVNet & hubSubnet
resource hubVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = { 
  name: hubVNetName 
  location: location 
  properties: { 
    addressSpace: { 
      addressPrefixes: [ 
        hubVNetAddress 
      ] 
    } 
    subnets: [ 
      hubSubnet1
      hubSubnet2
      hubSubnet3
    ]
  }
  // Get subnet information where VMs are connected.
  resource hubVMSubnet 'subnets' existing = {
    name: hubSubnetName1
  }
  // Get subnet information where VPN Gateway is connected.
  resource hubGatewaySubnet 'subnets' existing = {
    name: hubSubnetName3
  }
}

// create VM in hubVNet
// create public ip address for Linux VM
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${hubvmName1}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// create network interface for Linux VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${hubvmName1}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: hubVNet::hubVMSubnet.id
          }
        }
      }
    ]
  }
}

// create Linux vm in hub vnet
resource centosVM1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: hubvmName1
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
      computerName: hubvmName1
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
        name: '${hubvmName1}-disk'
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

// create public ip address for VPN Gateway
resource hubVPNGWpip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${hubVPNGWName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// create VPN Gateway for hub (RouteBased)
resource hubVPNGW 'Microsoft.Network/virtualNetworkGateways@2023-06-01' = {
  name: hubVPNGWName
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: '${hubVPNGWName}-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: hubVPNGWpip.id
          }
          subnet: {
            id: hubVNet::hubGatewaySubnet.id
          }
        }
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'vpngw1'
      tier: 'vpngw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}

// create local network gateway for azure vpn connection
resource hubLng 'Microsoft.Network/localNetworkGateways@2023-06-01' = {
  name: hubLngName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: ['${hubVNetAddress}', '${spoke1VNetAddress}', '${spoke2VNetAddress}']
    }
    gatewayIpAddress: hubVPNGWpip.properties.ipAddress
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

// return the vpn gateway ID and LNG ID to use from parent template
output hubVPNGWId string = hubVPNGW.id
output hubLngId string = hubLng.id
