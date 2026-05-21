// main.bicep
param location string = resourceGroup().location
param vmSize string = 'Standard_B2ms'
param adminUsername string = 'azureuser'
@secure()
param sshPublicKey string

// 1. Network Security Group (NSG)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'k8s-lab-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          protocol: 'Tcp'
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Allow-K8s-API'
        properties: {
          protocol: 'Tcp'
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '6443'
        }
      }
    ]
  }
}

// 2. Virtual Network & Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'k8s-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.240.0.0/16' ]
    }
    subnets: [
      {
        name: 'k8s-subnet'
        properties: {
          addressPrefix: '10.240.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Helper Module/Pattern for Public IPs
resource masterPublicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'master-node-public-ip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource workerPublicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'worker-node-1-public-ip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// 3. Network Interfaces (Enforcing Static Private IPs)
resource masterNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'master-node-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-master'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.240.0.10'
          publicIPAddress: { id: masterPublicIP.id }
          subnet: { id: vnet.properties.subnets[0].id }
        }
      }
    ]
  }
}

resource workerNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'worker-node-1-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-worker'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.240.0.11'
          publicIPAddress: { id: workerPublicIP.id }
          subnet: { id: vnet.properties.subnets[0].id }
        }
      }
    ]
  }
}

// 4. Virtual Machines
resource masterVM 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'master-node'
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: 'master-node'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              // It will look for your default local SSH key
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: masterNic.id } ]
    }
  }
}

resource workerVM 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'worker-node-1'
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: 'worker-node-1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: workerNic.id } ]
    }
  }
}
