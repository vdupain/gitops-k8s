# AGENTS.md

Reference guide for AI agents working on this repository.

## Stack

- **GitOps** : Flux CD (v2.7.5) + Kustomize
- **Clusters** : 4 (prod, staging, gpu-cluster, tf-cluster)
- **Secrets** : Bitnami SealedSecrets (files `.sealedsecret.yaml`)
- **CI** : GitHub Actions (`.github/workflows/main.yml`)
- **Domain** : `*.homelab.vincentdupain.com` (prod), `*.staging.vincentdupain.com` (staging)

## Validation

```bash
./scripts/validate.sh
```

Prerequisites: `yq` v4.34+, `kustomize` v5.3+, `kubeconform` v0.6+

The script skips Secrets (SealedSecret fields not valid in the schema).

## Architecture

```
clusters/<cluster>/            # Flux bootstrap + entrypoint Kustomizations
  flux-system/
    gotk-components.yaml       # Flux controllers
    gotk-sync.yaml             # Root GitRepository + Kustomization
  infrastructure.yaml          # Flux Kustomization CRs in chained dependency
  apps.yaml                    # Flux Kustomization CR → apps/clusters/<cluster>/
  infrastructure.configmap.yaml# Infra variables (IPs, cluster name)
  apps.configmap.yaml          # App variables (ingress hosts)

apps/base/<app>/               # Shared manifests
  namespace.yaml
  <app>.helmrepository.yaml
  <app>.helmrelease.yaml
  kustomization.yaml

apps/clusters/<cluster>/       # Overlays cluster
  kustomization.yaml            # Composes the enabled bases

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
| `staging` | Same as prod (different IPs and domain) | homepage, monitoring, podinfo |
| `gpu-cluster` | Cilium, ZFS, CoreDNS+etcd, ExternalDNS, Traefik, cert-manager, SealedSecrets | nvidia-device-plugin, open-webui |
| `tf-cluster` | tf-controller | Terraform CRs (Proxmox VM provisioning) |

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

## Agent skills

### Issue tracker

Issues and specs live on GitHub Issues (`gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Multi-context: `CONTEXT-MAP.md` at the root → one `CONTEXT.md` per domain (apps, infrastructure, clusters). System decisions in `docs/adr/`. See `docs/agents/domain.md`.
