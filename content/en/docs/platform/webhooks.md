---
title: Admission webhooks
linkTitle: Webhooks
weight: 25
description: >
  Validating admission webhooks for SecRule, SecAction, PhraseList, IPList, RuleSet, and WAF.
content_type: concept
---

kubeWAF registers **validating** admission webhooks so invalid CRs fail at
`kubectl apply` time instead of only at reconcile.

{{% alert title="Beta" color="info" %}}
Webhooks are enabled by default in the Helm chart (`webhooks.enabled=true`) with
a chart-generated self-signed CA. Rotate by deleting the `*-webhook-certs` Secret
and upgrading the release.
{{% /alert %}}

## What is validated

| Resource | Checks |
|----------|--------|
| **SecRule** | One-rule form (`match[]`) or `secLangRules` bag; match needs variables/collections/always-match; phase 1–5; warning if id ≤ 100000 |
| **SecAction** | Phase if set; metadata and/or actions present |
| **PhraseList** | `fileName` required; exactly one of `content` / `configMapRef` / `parts`; non-empty content |
| **IPList** | Same source constraints as PhraseList; soft-warn when inline lines are not IP/CIDR |
| **RuleSet** | Each `ruleRef` has name **xor** selector; kind in SecRule/SecAction/RuleSet/ConfigMap; `allowedRules.from=Selector` requires selector |
| **WAF** | `targetRef` / `targetRefs` (or nested `parentRefs`); `ruleRefs` may only be **RuleSet**; mode/provider enums; CRS paranoia 1–4; `telemetry.mode` and sample rates; reserved `metrics.extraLabels` keys (`waf_namespace`, `waf_name`, `engine`, `owner`) |

## Helm

```yaml
webhooks:
  enabled: true
  failurePolicy: Fail   # or Ignore during break-glass
```

Flags on the operator:

```text
--enable-webhooks=true
--webhook-cert-path=/tmp/k8s-webhook-server/serving-certs
```

## Disable

```bash
helm upgrade kubewaf oci://ghcr.io/kubewaf-io/charts/kubewaf \
  -n kubewaf-system \
  --version v0.1.0-beta.1 \
  --reuse-values \
  --set webhooks.enabled=false
```

From an operator checkout: `helm upgrade kubewaf ./charts/kubewaf -n kubewaf-system --set webhooks.enabled=false`.

## Related

- [Installation](/docs/platform/installation/)
- [WAF CRD reference](/docs/reference/crds/waf/)
- [Beta status](/docs/get-started/beta/)
