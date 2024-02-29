targetScope = 'subscription'

/*
------------------
param section
------------------
*/

// ---- param for Common ----
param resourceGroupName string
param resourceGroupLocation string
param myipaddress string

// ---- param for Hub ----
param hubVNetName string
param hubVNetAddress string
// VM Subnet
param hubSubnetName1 string 
param hubSubnetAddress1 string
// Firewall Subnet
param hubSubnetName2 string 
param hubSubnetAddress2 string
// VPN Gateway Subnet
param hubSubnetName3 string
param hubSubnetAddress3 string

// ---- param for Spoke1 ----
param spoke1VNetName string 
param spoke1VNetAddress string
// VM Subnets
param spoke1SubnetName1 string
param spoke1SubnetAddress1 string

// ---- param for Spoke2 ----
param spoke2VNetName string 
param spoke2VNetAddress string
// VM Subnets
param spoke2SubnetName1 string
param spoke2SubnetAddress1 string

// ---- param for Onpre ----
param onpreVNetName string
param onpreVNetAddress string
// VM Subnet
param onpreSubnetName1 string 
param onpreSubnetAddress1 string
// VPN Gateway Subnet
param onpreSubnetName2 string
param onpreSubnetAddress2 string

// ---- param for VM ----
param vmSizeLinux string
param hubvmName1 string
param spoke1vmName1 string
param spoke2vmName1 string
param onprevmName1 string
@secure()
param adminUserName string
@secure()
param adminPassword string

// ---- param for VPN Gateway ----
// Azure VPN Gateway
param hubVPNGWName string
param hubLngName string
// Onpre VPN Gateway
param onpreVPNGWName string
param onpreLngName string
// VPN Connection shared key (PSK)
@secure()
param connectionsharedkey string

/*
------------------
resource section
------------------
*/

resource newRG 'Microsoft.Resources/resourceGroups@2021-04-01' = { 
  name: resourceGroupName 
  location: resourceGroupLocation 
} 

/*
---------------
module section
---------------
*/

// Create Hub Environment (VM-Linux VNet, Subnet, NSG, VNet Peering, VPN Gateway, Local Network Gateway)
module HubModule './modules/hubEnv.bicep' = { 
  scope: newRG 
  name: 'CreateHubEnv' 
  params: { 
    location: resourceGroupLocation
    hubVNetName: hubVNetName
    hubVNetAddress: hubVNetAddress
    myipaddress: myipaddress
    hubSubnetName1: hubSubnetName1
    hubSubnetAddress1: hubSubnetAddress1
    hubSubnetName2: hubSubnetName2
    hubSubnetAddress2: hubSubnetAddress2
    hubSubnetName3: hubSubnetName3
    hubSubnetAddress3: hubSubnetAddress3
    hubvmName1: hubvmName1
    vmSizeLinux: vmSizeLinux
    adminUserName: adminUserName
    adminPassword: adminPassword
    hubVPNGWName: hubVPNGWName
    hubLngName: hubLngName
  } 
}

// Create Spoke1 Environment (VM-Linux, VNet, Subnet, NSG, Vnet Peering)
module Spoke1Module './modules/spoke1Env.bicep' = { 
  scope: newRG
  name: 'CreateSpoke1Env'
  params: {
    location: resourceGroupLocation
    hubVNetName: hubVNetName
    spoke1VNetName: spoke1VNetName
    spoke1VNetAddress: spoke1VNetAddress
    spoke1SubnetName1: spoke1SubnetName1
    spoke1SubnetAddress1: spoke1SubnetAddress1
    spoke1vmName1: spoke1vmName1
    vmSizeLinux: vmSizeLinux
    adminUserName: adminUserName
    adminPassword: adminPassword
  }
  dependsOn: [
    HubModule
  ]
}

// Create Spoke2 Environment (VM-Linux, VNet, Subnet, NSG, Vnet Peering)
module Spoke2Module './modules/spoke2Env.bicep' = { 
  scope: newRG
  name: 'CreateSpoke2Env'
  params: {
    location: resourceGroupLocation
    hubVNetName: hubVNetName
    spoke2VNetName: spoke2VNetName
    spoke2VNetAddress: spoke2VNetAddress
    spoke2SubnetName1: spoke2SubnetName1
    spoke2SubnetAddress1: spoke2SubnetAddress1
    spoke2vmName1: spoke2vmName1
    vmSizeLinux: vmSizeLinux
    adminUserName: adminUserName
    adminPassword: adminPassword
  }
  dependsOn: [
    HubModule
  ]
}

// Create Onpre Environment (VM-Linux VNet, Subnet, NSG, Vnet Peering, VPN Gateway, Local Network Gateway)
module OnpreModule './modules/onpreEnv.bicep' = { 
  scope: newRG 
  name: 'CreateOnpreEnv' 
  params: { 
    location: resourceGroupLocation
    onpreVNetName: onpreVNetName
    onpreVNetAddress: onpreVNetAddress
    onpreSubnetName1: onpreSubnetName1
    onpreSubnetAddress1: onpreSubnetAddress1
    onpreSubnetName2: onpreSubnetName2
    onpreSubnetAddress2: onpreSubnetAddress2
    onprevmName1: onprevmName1
    vmSizeLinux: vmSizeLinux
    adminUserName: adminUserName
    adminPassword: adminPassword
    onpreVPNGWName: onpreVPNGWName
    onpreLngName: onpreLngName
  } 
}

// Create Connection for Onpre VPN Gateway and Azure VPN Gateway
module VPNConnectionModule './modules/vpnConnection.bicep' = { 
  scope: newRG 
  name: 'CreateVPNConnection' 
  params: { 
    location: resourceGroupLocation
    hubVPNGWID: HubModule.outputs.hubVPNGWId
    hubLngID: HubModule.outputs.hubLngId
    onpreVPNGWID: OnpreModule.outputs.onpreVPNGWId
    onpreLngID: OnpreModule.outputs.onpreLngId
    connectionsharedkey: connectionsharedkey
  } 
  dependsOn: [
    HubModule
    OnpreModule
  ]
}
