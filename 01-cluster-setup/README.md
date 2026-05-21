# Domain 1: Cluster Setup
> *Exam Weight: 10%*

## 📖 Overview
In this domain, the goal is to establish a secure foundation. My lab uses a 2 node cluster hosted in Azure, which allows for testing node-level security and cross-node network policies.

## 🛠️ Infrastructure Baseline
- **Distribution:** Kubernetes v1.3x 
- **Nodes:** 1 Control-Plane, 1 Workers
- **CNI:** Cilium

## 🏗️ Deployment Steps
1. **Tooling:** Run deploy-k8s-vm.sh to deploy vms in Azure
2. **Config:** Then use bootstrap-k8s.sh to setup the cluster.
   **Cost Management:** lab-contol.sh is used to stop and restart the vms when needed.
   enable-admission-plugins: NodeRestriction,NamespaceLifecycle,ServiceAccount