---
title: "WAF engine"
description: "ModSecurity engine, CRS paths, mode, log level, and Wasm delivery"
weight: 20
content_type: task
aliases:
  - "/docs/tasks/engine/"
  - "/docs/kubewaf/operator/engine/"
---

A kubeWAF `WAF` resource evaluates traffic with **ModSecurity** via
[modsecurity-proxy-wasm](/engines/modsecurity-proxy-wasm/). The operator builds
plugin JSON and pushes it over **ECDS**. Optional
[PoW challenge](/docs/users/challenge/) runs **before** the WAF filter.

{{% alert title="Beta" color="warning" %}}
Field names can still evolve in beta. See [Beta status](/docs/get-started/beta/).
{{% /alert %}}

## Engine capabilities

| | **ModSecurity** |
|--|-----------------|
| Wasm module | [modsecurity-proxy-wasm](/engines/modsecurity-proxy-wasm/) |
| Path A CRS (`crsEnable: true`) | `Include @owasp_crs` — needs **full-catalog** wasm (`*-full`) |
| Path B CRS (structured SecRule CRs) | Preferred for GitOps |
| PhraseList / IPList (`data_files`) | Injects custom `@pmFromFile` / `@ipMatchFromFile` |
| FTW / product overlays | `@ftw-conf`, `@kubewaf-defaults` |

Deep dives:

- [modsecurity-proxy-wasm](/engines/modsecurity-proxy-wasm/)
- [pow-proxy-wasm](/engines/pow-proxy-wasm/) (challenge filter)

## Configure a WAF

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: shop-waf
  namespace: shop
spec:
  mode: DetectionOnly          # Blocking | DetectionOnly (beta-safe default for CRS)
  logLevel: 1                  # 0–7; default 1 (error) — avoid 7 in production
  crsEnable: false             # Path B: structured CRS RuleSets recommended for GitOps
  provider:
    type: EnvoyGateway         # or Auto / Istio / Cilium
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: external
  ruleRefs:
  - kind: RuleSet
    name: shop-rules
```

| Field | Description |
|-------|-------------|
| `mode` | `Blocking` → `SecRuleEngine On`; `DetectionOnly` → observe only |
| `logLevel` | Filter log verbosity `0`–`7` (default **1**) |
| `crsEnable` | Path A: engine-embedded CRS includes |
| `crs` | Paranoia, anomaly thresholds, remove-by-id/tag — [OWASP CRS](/docs/security/using-crs/) |
| `phraseListPolicy` | Missing custom PhraseList/IPList: `FailClosed` (default) or `IgnoreUnknown` |
| `ruleRefs` | RuleSets only (from a WAF) |

Prefer top-level **`targetRef` / `targetRefs`** for Envoy Gateway. Nested
`parentRefs` still resolves to the same targets.

## How config reaches Envoy

1. Operator resolves RuleSets → SecLang directives  
2. Resolves PhraseList/IPList + stock CRS `.data` → plugin `data_files`  
3. Builds plugin JSON (directives, data files, metrics labels, block message, …)  
4. Publishes **ECDS** resource `kubewaf/<namespace>/<waf-name>`  
5. Envoy loads Wasm from the operator wasm server

Operator-hosted modules:

```text
GET /wasm/modsecurity-proxy-wasm.wasm
GET /wasm/challenge-proxy-wasm.wasm
```

You do **not** hand-author plugin JSON for normal GitOps — the controller owns that mapping.
See [Data plane (ECDS)](/docs/platform/dataplane-ecds/).

## Wasm binaries

The operator loads Wasm from the image (and optional volume mount):

| Module | Path |
|--------|------|
| ModSecurity | `/wasm/modsecurity-proxy-wasm.wasm` |
| Challenge | `/wasm/challenge-proxy-wasm.wasm` |

Paths are also resolved under `KO_DATA_PATH/wasm` for ko-built images.

| Helm / flag | Purpose |
|-------------|---------|
| `dataplane.wasmServe.port` | Operator wasm HTTP port (default 18002) |
| `dataplane.wasmMountPath` | Mount path when using `dataplane.wasmVolume` |

Operator checkout: `git submodule update --init --recursive` then `make wasm-build` → `dist/wasm/`.

## Status

```bash
kubectl get waf
# Ready  Provider  Engine  Mode  Rules  Age

kubectl get waf shop-waf -o jsonpath='{.status.engine} {.status.mode} {.status.rulesLoaded}{"\n"}'
kubectl get waf shop-waf -o jsonpath='{.status.renderedDirectives}' | head
```

| Status field | Meaning |
|--------------|---------|
| `engine` | `ModSecurity` |
| `mode` | Effective Blocking / DetectionOnly |
| `rulesLoaded` | Count of resolved SecLang rules |
| `renderedDirectives` | Assembled SecLang (truncated in status) |
