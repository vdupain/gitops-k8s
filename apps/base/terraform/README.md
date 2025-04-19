# K8s TF

```sh
kubectl -n flux-system get secrets demo-cluster-output -o jsonpath='{.data.kube_config}' | base64 --decode > /tmp/demo-cluster.yaml
kubectl --kubeconfig /tmp/demo-cluster.yaml get pods -A
```
