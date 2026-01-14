using 'main.bicep'

param resourceGroupName = 'VPNGW-RG'
param resourceGroupLocation = 'japaneast'
// ---- for Firewall Rule ----
// your ip address for SSH (ex. xxx.xxx.xxx.xxx)
param myipaddress = '<Public IP your PC Address>'
// ---- param for Hub ----
param hubVNetName = 'Hub-VNet'
param hubVNetAddress = '10.0.0.0/16'
param hubSubnetName1 = 'Hub-VMSubnet'
param hubSubnetAddress1 = '10.0.0.0/24'
param hubSubnetName2 = 'AzureFirewallSubnet'
param hubSubnetAddress2 = '10.0.110.0/26'
param hubSubnetName3 = 'GatewaySubnet'
param hubSubnetAddress3 = '10.0.200.0/27'
// for VPN Gateway
param hubVPNGWName = 'azure-vpngw'
param hubLngName = 'Azure-LNG'
// To set the DNS name of the public IP address, the vm name must be specified in lower case.
param hubvmName1 = 'hub-jump-centos'
// ---- param for Spoke1 ----
param spoke1VNetName = 'Spoke1-VNet' 
param spoke1VNetAddress = '10.1.0.0/16'
param spoke1SubnetName1 = 'Spoke1-VMSubnet'
param spoke1SubnetAddress1 = '10.1.0.0/24' 
param spoke1vmName1 = 'spoke1-centos-01'
// ---- param for Spoke2 ----
param spoke2VNetName = 'Spoke2-VNet' 
param spoke2VNetAddress = '10.2.0.0/16'
param spoke2SubnetName1 = 'Spoke2-VMSubnet'
param spoke2SubnetAddress1 = '10.2.0.0/24' 
param spoke2vmName1 = 'spoke2-centos-01'
// ---- param for Onpre ----
param onpreVNetName = 'Onpre-VNet' 
param onpreVNetAddress = '172.16.0.0/16'
param onpreSubnetName1 = 'Onpre-VMSubnet'
param onpreSubnetAddress1 = '172.16.0.0/24'
param onpreSubnetName2 = 'GatewaySubnet'
param onpreSubnetAddress2 = '172.16.200.0/27'
param onprevmName1 = 'onpre-centos-01'
param onpreVPNGWName = 'onpre-vpngw'
param onpreLngName = 'Onpre-LNG'
// ---- Common param for VM ----
param vmSizeLinux = 'Standard_B2s'
param adminUserName = 'cloudadmin'
param adminPassword = 'msjapan1!msjapan1!'
// ---- Optional: Spot VM (discount) ----
// If true, all Linux VMs in this environment will be created as Spot VMs.
param useSpotVm = false
// ---- Common param for VPNGW ----
param connectionsharedkey = 'msjapan1!msjapan1!'
