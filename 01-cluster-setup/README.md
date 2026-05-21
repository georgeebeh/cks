# Domain 1: Cluster Setup
> *Exam Weight: 10%*

## 📖 Overview
In this domain, the goal is to establish a secure foundation. My lab uses `kind` (Kubernetes in Docker) to simulate a multi-node environment, which allows for testing node-level security and cross-node network policies.

## 🛠️ Infrastructure Baseline
- **Distribution:** Kubernetes v1.3x (via kind)
- **Nodes:** 1 Control-Plane, 2 Workers
- **CNI:** Default kindnet (Note: Switch to Calico/Cilium for advanced NetworkPolicy labs)

## 🏗️ Deployment Steps
1. **Tooling:** Installed `kind` and `kubectl` on WSL2 (Ubuntu 24.04).
2. **Config:** Used `kind-cks.yaml` to bootstrap with specific admission controllers.
   ```yaml
   enable-admission-plugins: NodeRestriction,NamespaceLifecycle,ServiceAccount