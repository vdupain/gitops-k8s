# Falco

## Docs

* <https://falco.org/blog/deploy-falco-talos-cluster/>
* <https://falco.org/blog/falco-atomic-red/>

## Update rules

``` sh
kubectl apply -f falco-rules.configmap.yaml
kubectl rollout restart daemonset falco -n falco
```