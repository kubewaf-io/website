---
title: Beta status and limitations
linkTitle: Beta status
weight: 5
description: >
  What “beta” means for kubeWAF v0.1, API stability, and known gaps before production GA.
content_type: concept
---

kubeWAF is in **beta**. Chart and app version **`0.1.0-beta.1`** ship under
`v1beta1` CRDs. APIs and defaults may still change with community feedback.

{{% alert title="Not GA" color="warning" %}}
Do **not** treat beta as a frozen production contract. Use **DetectionOnly** mode
for first CRS rollouts, pin image digests, and plan for CRD migrations.
{{% /alert %}}

## What is ready

| Area | Status |
|------|--------|
| `SecRule` / `SecAction` / `RuleSet` / `WAF` / `PhraseList` / `IPList` / `SecRuleIDPool` | Usable (`v1beta1`) |
| Helm `kubewaf` + `kubewaf-crs` | Usable (`0.1.0-beta.1`) |
| Validating admission webhooks | On by default — [Webhooks](/docs/platform/webhooks/) |
| ECDS config push + operator-hosted Wasm HTTP | Usable; unresolved refs keep the last good snapshot |
| Envoy Gateway Extension Server slot | **Primary** supported path |
| Istio EnvoyFilter / Cilium CEC (`config_discovery`) slots | Implemented; Cilium needs bootstrap-static `kubewaf_ecds` |
| Path B CRS (`kubewaf-crs` + `crsEnable: false`) | Default / first-class |
| Path A CRS (`crsEnable: true`) | Needs full-catalog wasm (`*-full`) |
| `spec.mode`: Blocking / DetectionOnly | Usable |
| Status: Ready, rules loaded, rendered directives (capped) | Usable |
| kubectl printer columns + events | Usable |
| Probe / metrics / traces subresources | Opt-in Helm (`subresourceApi`) — [Observability](/docs/platform/observability/) |
| Provider e2e | PR + release: EG smoke, Path B FTW, Istio, Cilium |

## Known limitations (beta)

| Gap | Notes |
|-----|--------|
| **API may change** | Prefer top-level `targetRef` / `targetRefs`. Nested `parentRefs` still resolves. |
| **Cross-namespace policy** | `RuleSet.spec.allowedRules` is enforced; WAF may still attach cross-namespace RuleSets (platform packs). Review tenancy carefully. |
| **Rendered status size** | `status.renderedDirectives` is capped (~64KiB) for large Path B assemblies. |
| **Provider parity** | Envoy Gateway is the best-documented path. Istio/Cilium need mesh-specific Wasm readiness. |
| **Cilium traces** | CEC does not embed an OTel access logger. Remesh adds STATIC `kubewaf_otel` + `stats_tags` only. Catalog OTLP and eval capture do not run on Cilium 1.19. |
| **Webhook certs** | Helm self-signed CA. Rotate by deleting `*-webhook-certs` and upgrading. |
| **Observability** | Managed OTLP path is opt-in; series names can evolve. |
| **Community process docs** | Security reporting and contribution rules live under [Contribute](/docs/contribute/). |

## Safe rollout defaults

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: shop
spec:
  mode: DetectionOnly   # SecRuleEngine DetectionOnly — observe first
  logLevel: 1           # error (default); raise only while debugging
  # ...
```

1. Install with Helm ([Installation](/docs/platform/installation/)).  
2. Attach RuleSets in **DetectionOnly**.  
3. Watch interruptions / metrics ([Observability](/docs/platform/observability/)).  
4. Flip `mode: Blocking` when false positives are acceptable.

## Versioning

| Artifact | Beta value |
|----------|------------|
| Helm chart | `0.1.0-beta.1` |
| `appVersion` | `0.1.0-beta.1` |
| CRD API | `seclang.kubewaf.io/v1beta1`, `waf.kubewaf.io/v1beta1` |
| Changelog | [GitHub CHANGELOG](https://github.com/kubewaf-io/kubewaf/blob/main/CHANGELOG.md) |

## Related

- [Installation](/docs/platform/installation/)
- [WAF engine matrix](/docs/platform/engine/)
- [Gateway providers](/docs/platform/providers/)
- [Quick start](/docs/get-started/quickstart/)
- [Security reporting](/docs/contribute/security/)
