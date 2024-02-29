/*
------------------
param section
------------------
*/
// Common
param location string
// Azure VPN Gateway
param hubVPNGWID string
param hubLngID string
// On-premises VPN Gateway
param onpreVPNGWID string
param onpreLngID string
// VPN Connection shared key (PSK)
param connectionsharedkey string

/*
------------------
resource section
------------------
*/
// Create a connection from Azure to On-premises
resource AzuretoOnpre_Connection 'Microsoft.Network/connections@2023-06-01' = {
  name: 'Azure-to-Onpre'
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: hubVPNGWID
      properties: {}
    }
    localNetworkGateway2: {
      id: onpreLngID
      properties: {}
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: connectionsharedkey
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 45
    connectionMode: 'Default'
    gatewayCustomBgpIpAddresses: []
  }
}

// Create a connection from On-premises to Azure
resource OnpretoAzure_Connection 'Microsoft.Network/connections@2023-06-01' = {
  name: 'Onpre-to-Azure'
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: onpreVPNGWID
      properties: {}
    }
    localNetworkGateway2: {
      id: hubLngID
      properties: {}
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: connectionsharedkey
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 45
    connectionMode: 'Default'
    gatewayCustomBgpIpAddresses: []
  }
}
