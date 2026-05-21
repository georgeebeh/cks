#!/bin/bash
# deploy-k8s-vms.sh (Fully Robust NSG Edition)

RESOURCE_GROUP="CKS-Lab-RG"
LOCATION="eastus"
VNET_NAME="k8s-vnet"
SUBNET_NAME="k8s-subnet"
NSG_NAME="k8s-lab-nsg"
VM_SIZE="Standard_B2ms"
IMAGE="Ubuntu2204"
ADMIN_USER="azureuser"

echo "Creating Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating Network Security Group (NSG)..."
az network nsg create --resource-group $RESOURCE_GROUP --name $NSG_NAME

echo "Adding SSH (22) rule to NSG..."
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name Allow-SSH \
  --protocol Tcp \
  --direction Inbound \
  --priority 1000 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow

echo "Adding Kubernetes API (6443) rule to NSG..."
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name Allow-K8s-API \
  --protocol Tcp \
  --direction Inbound \
  --priority 1010 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 6443 \
  --access Allow

echo "Creating VNet and Subnet (Bound to our NSG)..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefixes 10.240.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefixes 10.240.0.0/24 \
  --nsg $NSG_NAME

# Create Control Plane Node with Static Internal IP
echo "Deploying Control Plane VM (master-node)..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name "master-node" \
  --image $IMAGE \
  --size $VM_SIZE \
  --admin-username $ADMIN_USER \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --nsg "" \
  --public-ip-sku Standard \
  --private-ip-address 10.240.0.10 \
  --generate-ssh-keys

# Create Worker Node with Static Internal IP
echo "Deploying Worker VM (worker-node-1)..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name "worker-node-1" \
  --image $IMAGE \
  --size $VM_SIZE \
  --admin-username $ADMIN_USER \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --nsg "" \
  --public-ip-sku Standard \
  --private-ip-address 10.240.0.11 \
  --generate-ssh-keys

echo "---------------------------------------------------------------"
echo "VMs successfully deployed behind a unified NSG!"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --output table