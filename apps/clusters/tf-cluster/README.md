# K8s TF

```sh
kubectl -n flux-system get secrets demo-pve1-cluster-output -o jsonpath='{.data.kube_config}' | base64 --decode > /tmp/demo-pve1-cluster.yaml
kubectl -n flux-system get secrets demo-pve3-cluster-output -o jsonpath='{.data.kube_config}' | base64 --decode > /tmp/demo-pve3-cluster.yaml
```

```sh
kubectl --kubeconfig /tmp/demo-pve1-cluster.yaml get pods -A
kubectl --kubeconfig /tmp/demo-pve3-cluster.yaml get pods -A
```
