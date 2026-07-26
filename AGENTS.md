# AGENTS.md

Guide de référence pour les agents IA travaillant sur ce dépôt.

## Stack

- **GitOps** : Flux CD (v2.7.5) + Kustomize
- **Clusters** : 4 (prod, staging, gpu-cluster, tf-cluster)
- **Secrets** : Bitnami SealedSecrets (fichiers `.sealedsecret.yaml`)
- **CI** : GitHub Actions (`.github/workflows/main.yml`)
- **Domaine** : `*.homelab.vincentdupain.com` (prod), `*.staging.vincentdupain.com` (staging)

## Validation

```bash
./scripts/validate.sh
```

Prerequisites: `yq` v4.34+, `kustomize` v5.3+, `kubeconform` v0.6+

Le script skippe les Secrets (champs SealedSecret non valides en schéma).

## Architecture

```
clusters/<cluster>/            # Flux bootstrap + entrypoint Kustomizations
  flux-system/
    gotk-components.yaml       # Flux controllers
    gotk-sync.yaml             # Root GitRepository + Kustomization
  infrastructure.yaml          # Flux Kustomization CRs en dépendance chaînée
  apps.yaml                    # Flux Kustomization CR → apps/clusters/<cluster>/
  infrastructure.configmap.yaml# Variables infra (IPs, nom du cluster)
  apps.configmap.yaml          # Variables apps (ingress hosts)

apps/base/<app>/               # Manifests partagés
  namespace.yaml
  <app>.helmrepository.yaml
  <app>.helmrelease.yaml
  kustomization.yaml

apps/clusters/<cluster>/       # Overlays cluster
  kustomization.yaml            # Compose les bases activées

infrastructure/
  cilium/                      # Cilium CNI (L2 announcement, IP pool)
  controllers/
    storage/                   # ZFS LocalPV (default StorageClass)
    network/                   # CoreDNS+etcd, ExternalDNS, Traefik
    security/                  # cert-manager, sealed-secrets
    monitoring/                # Prometheus/Grafana, metrics-server
    cnpg/                      # CloudNativePG operator
  security-config/             # cert-manager webhook OVH + ClusterIssuer
  tf/                          # tf-controller
```

## Clusters

| Cluster | Infra | Apps |
|---------|-------|------|
| `prod` | Cilium, ZFS, CoreDNS+etcd, ExternalDNS, Traefik, cert-manager, Prometheus/Grafana, SealedSecrets, CNPG, monitoring | homepage, monitoring, podinfo |
| `staging` | Identique à prod (IPs et domaine différents) | homepage, monitoring, podinfo |
| `gpu-cluster` | Cilium, ZFS, CoreDNS+etcd, ExternalDNS, Traefik, cert-manager, SealedSecrets | nvidia-device-plugin, open-webui |
| `tf-cluster` | tf-controller | Terraform CRs (provisionnement VMs Proxmox) |

## App Patterns

Most apps under `apps/base/<app>/` follow this pattern:
- `namespace.yaml` — Namespace
- `<app>.helmrepository.yaml` — `HelmRepository` CR
- `<app>.helmrelease.yaml` — `HelmRelease` CR
- `kustomization.yaml` — wires them together

## Variable Injection

Cluster-scoped variables are stored in ConfigMaps in `clusters/<cluster>/`:
- `infrastructure.configmap.yaml` — IP pools, domain, cluster name
- `apps.configmap.yaml` — ingress hostnames

Referenced via Flux `postBuild.substituteFrom` in `infrastructure.yaml` and `apps.yaml`.

## Secrets

Secrets are managed with **Bitnami SealedSecrets** (`.sealedsecret.yaml` committed, `.secret.yaml` gitignored). The `scripts/sealedsecret.sh` script validates and re-seals them.

Storage class `zfs` (OpenEBS ZFS LocalPV) is the default.

## Retrieving Terraform-provisioned Cluster Kubeconfigs

```bash
kubectl -n flux-system get secrets demo-pve1-cluster-output -o jsonpath='{.data.kube_config}' | base64 --decode > /tmp/demo-pve1-cluster.yaml
kubectl --kubeconfig /tmp/demo-pve1-cluster.yaml get pods -A
```
