---
title: Gateway providers
linkTitle: Providers
weight: 40
description: >
  Wire kubeWAF to Envoy Gateway, Istio, or Cilium so WAF policy attaches to live traffic.
content_type: concept
---

kubeWAF publishes portable filter config over **ECDS** and installs a **provider-specific slot**
so Envoy loads the Wasm modules. Pick the guide that matches your data plane.

| Provider | Maturity (beta) | When to use |
|----------|-----------------|-------------|
| [Envoy Gateway](envoy-gateway/) | **Primary** path — best docs + e2e focus | Gateway API + Envoy Gateway |
| [Istio](istio/) | Implemented (EnvoyFilter slot) | Istio ingress or mesh; validate Wasm in your build |
| [Cilium](cilium/) | Implemented (CEC + ECDS) | Cilium L7 / Gateway; bootstrap-static `kubewaf_ecds` required |

{{% alert title="Auto provider" color="info" %}}
`spec.provider.type: Auto` (default) discovers the data plane from GatewayClass /
installed CRDs and records the result in `status.provider` + `status.providerDetection`.
{{% /alert %}}

Background: [Data plane (ECDS)](../dataplane-ecds/), [Beta status](/docs/get-started/beta/).
