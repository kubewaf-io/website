---
title: "WAF"
description: "WAF custom resource reference"
weight: 30
content_type: reference
---

**Group**: `waf.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `WAF`  
**Short name**: `waf`

{{% alert title="Beta API" color="warning" %}}
`v1beta1` may change. See [Beta status](/docs/get-started/beta/).
{{% /alert %}}

## Purpose

`WAF` attaches **RuleSets** to a data-plane **provider**, runs the **ModSecurity**
Wasm filter, optionally installs a **PoW challenge** filter first, and pushes
configuration over **ECDS**.

Guides: [WAF engine](/docs/platform/engine/), [Providers](/docs/platform/providers/),
[Protect a service](/docs/users/protect-a-service/).

## Spec overview

```yaml
spec:
  # Prefer top-level targetRef (Envoy Gateway policy attachment)
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: external
  # Nested parentRefs also resolves

  provider:
    type: Auto | EnvoyGateway | Istio | Cilium
    # provider-specific: istio / cilium / ecds overrides …

  mode: Blocking | DetectionOnly   # default Blocking; use DetectionOnly for CRS rollout
  logLevel: 0-7                    # default 1 (error)

  challenge:                       # optional, before WAF
    enabled: bool
    secret: string
    secretRef: { name, key }
    baseDifficulty / minDifficulty / maxDifficulty: int
    header / headerValue: string

  ruleRefs: []RuleRef              # RuleSet only
  crsEnable: bool                  # Path A engine CRS includes
  crs: CRSTuning                   # paranoia / thresholds / exclusions
  phraseListPolicy: FailClosed | IgnoreUnknown  # missing PhraseList/IPList

  metrics: WAFMetrics
  telemetry:                       # opt-in managed OTLP annotations
    mode: None | Managed
  block: WAFBlock                  # ModSecurity deny local-reply cosmetics
```

## Mode

| Field | Values | Notes |
|-------|--------|--------|
| `mode` | `Blocking`, `DetectionOnly` | Maps to `SecRuleEngine On` / `DetectionOnly` |
| `logLevel` | `0`–`7` | Default **1**; avoid max debug in prod |

```yaml
spec:
  mode: DetectionOnly
  crsEnable: false          # Path B: attach structured CRS RuleSets
  crs:
    paranoiaLevel: 1
```

## Challenge (Proof-of-Work)

Optional PoW filter **before** the WAF: [Proof-of-Work challenge](/docs/users/challenge/).

```yaml
spec:
  challenge:
    enabled: true
    baseDifficulty: 18
```

Status: `challengeEnabled`, `challengeSecretName`.  
ECDS names: challenge `kubewaf/<ns>/<name>/challenge`, WAF `kubewaf/<ns>/<name>`.

## Attachment (targetRef)

```yaml
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: external
```

Nested form (also resolves):

```yaml
spec:
  parentRefs:
    targetRef:
      group: gateway.networking.k8s.io
      kind: Gateway
      name: external
```

## provider

| `type` | Slot |
|--------|------|
| `Auto` | Discover from GatewayClass / CRDs (default) |
| `EnvoyGateway` | Extension Server hooks |
| `Istio` | `EnvoyFilter` |
| `Cilium` | `CiliumEnvoyConfig` |

## ruleRefs

**RuleSet** only (not raw SecRules). Nested RuleSets flatten recursively.

If a ref is missing or `allowedRules` rejects it, `ReferencesResolved` is False
and the operator does **not** publish a new ECDS snapshot. Envoy keeps the last
good config.

## crsEnable / crs

- **Path A** (`crsEnable: true`): engine `Include @owasp_crs` — needs full-catalog wasm (`*-full`).  
- **Path B** (`crsEnable: false` + RuleSets of SecRules): preferred for GitOps.  
- `crs` tuning applies to either path — [OWASP CRS](/docs/security/using-crs/).

## phraseListPolicy

Controls publish when assembled SecLang references a **custom** `@pmFromFile` /
`@ipMatchFromFile` basename with no Ready [PhraseList](../phraselist/) or
[IPList](../iplist/) in the WAF namespace. Applies to **ModSecurity** only;
data_files injection is always enabled.

| Value | Behavior |
|-------|----------|
| `FailClosed` (default) | Refuse ECDS publish; condition `PhraseListsResolved` False |
| `IgnoreUnknown` | Drop SecLang lines for unresolved custom basenames, then publish |

Stock CRS basenames are always resolved from the operator CRS pack (unless an
annotated PhraseList override is admitted). See [Phrase & IP lists](/docs/users/data-files/).

```yaml
spec:
  phraseListPolicy: FailClosed
```

## Wasm binaries

The operator serves ModSecurity and optional challenge Wasm from:

| Module | Path |
|--------|------|
| ModSecurity | `/wasm/modsecurity-proxy-wasm.wasm` |
| Challenge | `/wasm/challenge-proxy-wasm.wasm` |

## metrics

```yaml
metrics:
  extraLabels:
    team: payments
  includeRuleID: true
  enableStats: true
```

`extraLabels` cannot override reserved keys (`waf_namespace`, `waf_name`, `engine`, `owner`).

## telemetry

Opt-in managed export. Wasm only annotates; Envoy sends OTLP to cluster `kubewaf_otel`.

```yaml
spec:
  telemetry:
    mode: Managed
    traces:
      enabled: true
      sampleRate: "0.25"
      sampleDisruptive: "1.0"
      redact: true
      includeMatchData: false
```

See [Observability](/docs/platform/observability/) and [Capture](/docs/platform/observability/capture/).

## block

Client-visible deny local-replies. Defaults are product-neutral
(`Forbidden`, optional `x-blocked` marker).

## Status

```yaml
status:
  provider: EnvoyGateway
  providerDetection: "explicit (spec.provider.type)"
  engine: ModSecurity
  mode: DetectionOnly
  rulesLoaded: 42
  actionsLoaded: 3
  directivesCount: 120
  renderedDirectives: |
    SecRuleEngine DetectionOnly
    ...
  renderedDirectivesTruncated: false
  challengeEnabled: true
  dataFilesCount: 3
  dataFilesRawBytes: 171000
  dataFilesContentHash: "…"
  ecdsResourceName: kubewaf/shop/shop-waf
  ecdsVersion: 42
  slotKind: ExtensionServer
  conditions:
  - type: Ready
    status: "True"
  - type: ReferencesResolved
    status: "True"
  - type: PhraseListsResolved
    status: "True"
```

| Status field | Meaning |
|--------------|---------|
| `dataFilesCount` / `dataFilesRawBytes` / `dataFilesContentHash` | Injected PhraseList/IPList/CRS `.data` bodies |
| `PhraseListsResolved` | Outcome of list discovery (includes IPList) |

```bash
kubectl get waf
# Ready  Provider  Engine  Mode  Rules  Age
```

## Related

- [WAF engine](/docs/platform/engine/)
- [RuleSet](/docs/reference/crds/ruleset/)
- [SecRule](/docs/reference/crds/secrule/)
- [PhraseList](/docs/reference/crds/phraselist/) / [IPList](/docs/reference/crds/iplist/)
- [SecRuleIDPool](/docs/reference/crds/secruleidpool/)
- [Phrase & IP lists](/docs/users/data-files/)
- [Probes](/docs/platform/observability/probes/)
