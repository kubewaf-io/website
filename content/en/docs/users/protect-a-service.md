---

title: "Protect a service end to end"
linkTitle: "Protect a service"
description: "Tutorial: attach a WAF and Path B CRS to an HTTP service behind Envoy Gateway"
weight: 10
content_type: tutorial
aliases:
  - "/docs/tutorials/protect-a-service/"
---

This tutorial walks through protecting a simple HTTP service with kubeWAF and Envoy Gateway.
The **platform team** installs the operator (and optional `kubewaf-crs`). You attach a `WAF` and confirm it is Ready.

## Objectives

- Deploy a sample backend and HTTPRoute
- Attach `ruleset-api` (from `kubewaf-crs`) on a `WAF`
- Confirm benign traffic is allowed; start in DetectionOnly, then Blocking if you want denies

## Prerequisites

- Platform has installed kubeWAF ([Installation](/docs/platform/installation/)) and wired Envoy Gateway ([provider guide](/docs/platform/providers/envoy-gateway/))
- `kubewaf-crs` is installed if you want `ruleset-api` (same [installation](/docs/platform/installation/#crs-as-kubernetes-objects-optional) page)
- `kubectl` in a namespace you can write `WAF` / `HTTPRoute` objects

## Steps

### 1. Deploy a sample application

Deploy any HTTP echo or demo service in a namespace you control, and expose it with an
`HTTPRoute` (or Gateway API route your provider uses).

### 2. Attach a WAF

`ruleset-api` is on by default in the `kubewaf-crs` chart:

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: demo-waf
  namespace: default
spec:
  mode: DetectionOnly      # observe first; set Blocking to deny
  provider:
    type: EnvoyGateway
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: demo
  ruleRefs:
  - kind: RuleSet
    name: ruleset-api
    group: waf.kubewaf.io
    version: v1beta1
  crsEnable: false
  crs:
    paranoiaLevel: 1
```

Exact fields: [WAF CRD](/docs/reference/crds/waf/), [OWASP CRS](/docs/security/using-crs/).

### 3. Send test traffic

1. **Benign GET** — expect `200` from the backend.
2. **Attack-like query** (classic XSS/SQLi) — DetectionOnly still returns `200` and scores.
   Set `mode: Blocking` when you want a 403.

Check operator and Envoy logs if results are unexpected:
[Troubleshooting](/docs/platform/troubleshooting/).

## Next steps

- [Write custom SecRules](/docs/security/writing-rules/)
- [Add a PoW challenge](/docs/users/challenge/)
- [Wire Istio or Cilium](/docs/platform/dataplane-ecds/)
- Engine deep-dives: [Engines docs](/engines/)
