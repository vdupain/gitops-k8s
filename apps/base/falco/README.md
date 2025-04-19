# Falco

## Docs

* <https://falco.org/blog/deploy-falco-talos-cluster/>
* <https://falco.org/blog/falco-atomic-red/>

## Update rules

```
kubectl apply -f custom-rules.configmap.yaml
kubectl rollout restart daemonset falco -n falco
```