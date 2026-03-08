# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A GitOps repository for managing multiple homelab Kubernetes clusters using **Flux CD** and **Kustomize**. Changes pushed to `main` are automatically reconciled by Flux onto the target clusters.

## Validation

```bash
# Validate all YAML and kustomize overlays against Flux CRD schemas
./scripts/validate.sh
```

Prerequisites: `yq` v4.34+, `kustomize` v5.3+, `kubeconform` v0.6+

The script skips Secrets validation (SOPS-encrypted fields would fail schema checks).

## Architecture

### Directory Layout

```
clusters/<cluster-name>/     # Flux bootstrap per cluster (gotk-components, gotk-sync, entrypoint Kustomizations)
apps/base/<app>/             # Shared app manifests (HelmRelease, namespace, HelmRepository, ConfigMaps)
apps/clusters/<cluster>/     # Cluster-specific Kustomize overlays that reference base layers
infrastructure/              # Core infra: Cilium CNI, namespaces, storage, tf-controller
```

### How Flux Wires Everything Together

Each cluster's `clusters/<name>/` directory contains a Flux `Kustomization` CR (e.g. `apps.yaml`) that points Flux at `apps/clusters/<cluster-name>/`. That cluster overlay's `kustomization.yaml` composes base layers (e.g. `../../base/nvidia`, `../../base/ai/open-webui`). Flux reconciles the resulting manifests onto the cluster on a ~10-minute interval.

Cluster-scoped variables (ingress hostnames, etc.) are injected via a `ConfigMap` in `clusters/<cluster>/apps.configmap.yaml` and referenced by Flux's variable substitution in HelmRelease/Kustomization specs.

### Clusters

| Cluster | Purpose |
|---|---|
| `prod` | Main homelab cluster; full app suite with ingress hostnames |
| `staging` | Staging cluster; mirrors prod |
| `gpu-cluster` | GPU workloads (nvidia device plugin, Open WebUI/Ollama) |
| `tf-cluster` | Runs `tf-controller` to manage Proxmox VMs via Terraform GitOps |

### Infrastructure Layer

- **Cilium** — CNI with L2 advertisement (`CiliumL2AnnouncementPolicy` + `CiliumLoadBalancerIPPool`) for bare-metal LoadBalancer IPs
- **local-path-storage** — default StorageClass for PVCs
- **tf-controller** — Flux-native Terraform runner; `Terraform` CRs in `apps/base/terraform/` and `apps/clusters/tf-cluster/` provision Proxmox VMs

### App Patterns

Most apps under `apps/base/<app>/` follow this pattern:
- `namespace.yaml` — Namespace
- `repository.yaml` — `HelmRepository` CR
- `release.yaml` — `HelmRelease` CR (values often in a sibling `*.values.configmap.yaml`)
- `kustomization.yaml` — wires them together

### Secrets

Secrets are SOPS-encrypted. The validate script skips Secret resources to avoid schema failures on encrypted fields.

### Retrieving Terraform-provisioned Cluster Kubeconfigs

```bash
kubectl -n flux-system get secrets demo-pve1-cluster-output -o jsonpath='{.data.kube_config}' | base64 --decode > /tmp/demo-pve1-cluster.yaml
kubectl --kubeconfig /tmp/demo-pve1-cluster.yaml get pods -A
```

### Updating Falco Rules

```bash
kubectl apply -f apps/base/falco/custom-rules.configmap.yaml
kubectl rollout restart daemonset falco -n falco
```
