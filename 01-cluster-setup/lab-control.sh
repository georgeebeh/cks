#!/bin/bash
# lab-control.sh - Local script to manage CKS Lab VMs

RESOURCE_GROUP="CKS-Lab-RG"
VM_MASTER="master-node"
VM_WORKER="worker-node-1"

show_usage() {
    echo "Usage: $0 [start|stop|status]"
    echo "  start  : Spin up the lab and display public IPs"
    echo "  stop   : Deallocate VMs to stop incurring charges"
    echo "  status : Check the current power state of the VMs"
}

if [ "$#" -ne 1 ]; then
    show_usage
    exit 1
fi

case "$1" in
    start)
        echo "=== Waking up CKS Lab Environment ==="
        # Start VMs concurrently to save time
        az vm start --resource-group $RESOURCE_GROUP --name $VM_MASTER --no-wait
        az vm start --resource-group $RESOURCE_GROUP --name $VM_WORKER
        
        echo "Waiting a few seconds for network interfaces to stabilize..."
        sleep 10
        
        echo "=== Lab is Online! Fetching Connection Details ==="
        az vm list-ip-addresses --resource-group $RESOURCE_GROUP --output table
        ;;
        
    stop)
        echo "=== Shutting Down CKS Lab (Deallocating Resources) ==="
        # Deallocate means Azure frees up the underlying hardware so billing STOPS completely
        az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_MASTER --no-wait
        az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_WORKER
        echo "Shutdown signals sent. VMs are deallocating in the background."
        ;;
        
    status)
        echo "=== Current VM Power States ==="
        az vm list -d --resource-group $RESOURCE_GROUP --query "[].{Name:name, PowerState:powerState}" --output table
        ;;
        
    *)
        show_usage
        exit 1
        ;;
esac