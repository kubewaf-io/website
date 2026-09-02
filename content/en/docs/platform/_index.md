---
title: Platform administrators
linkTitle: Platform
main_menu: false
weight: 30
description: >
  Install and operate kubeWAF cluster-wide — operator, Wasm delivery, gateway
  providers, multi-tenant boundaries, and observability.
content_type: concept
cascade:
  type: docs
---

You run Kubernetes and the ingress/mesh stack. Your job is to install the operator,
wire Envoy Gateway / Istio / Cilium, deliver Wasm modules, and keep protection
healthy across teams.

{{% pageinfo %}}
**Application teams** who only need a `WAF` on their Gateway should start under
[Application teams](/docs/users/) instead.
{{% /pageinfo %}}

## What you own

| Area | Pages |
|------|--------|
| Install the operator (and optional `kubewaf-crs`) | [Installation](installation/) |
| Configure the WAF engine | [WAF engine](engine/) (ModSecurity) |
| Admission webhooks | [Webhooks](webhooks/) |
| Beta limitations | [Beta status](/docs/get-started/beta/) |
| How config reaches Envoy | [Data plane (ECDS)](dataplane-ecds/) |
| Provider wiring | [Envoy Gateway](providers/envoy-gateway/), [Istio](providers/istio/), [Cilium](providers/cilium/) |
| Metrics, capture, probes | [Observability](observability/) — [capture](observability/capture/), [probes](observability/probes/) |
| Break/fix | [Troubleshooting](troubleshooting/) |

## Recommended path

1. [Installation](installation/) (Helm; Wasm from image `/wasm`)  
2. Provider guide for your stack under [Providers](providers/)  
3. [Observability](observability/) so teams can see blocks  
4. Skim [Architecture](/docs/get-started/architecture/) and [Data plane (ECDS)](dataplane-ecds/) when debugging

Cross-namespace rule sharing and `allowedRules` are documented with
[RuleSets](/docs/users/rulesets/) (security and app teams author packs; you set the tenancy model).
