@description('Environment name')
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('OpenClaw gateway port')
param openclawPort int = 18789

@description('Source CIDR for SSH access')
param sshSourceCidr string = '*'

@description('Source CIDR for gateway access')
param gatewaySourceCidr string = '*'

@description('Resource tags')
param tags object = {}

var namePrefix = 'openclaw-${environment}'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${namePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${namePrefix}-subnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${namePrefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: sshSourceCidr
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'AllowOpenClawGateway'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: gatewaySourceCidr
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: string(openclawPort)
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output subnetId string = vnet.properties.subnets[0].id
