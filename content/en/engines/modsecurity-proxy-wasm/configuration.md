---
title: "Configuration"
description: "Plugin JSON, embedded CRS includes, metrics, and security logs"
weight: 20
content_type: concept
---
## Plugin JSON

The filter is configured with a JSON object (Envoy Wasm `configuration` or
kubeWAF-generated ECDS payload). Shape overview:

```json
{
  "mode": "kubewaf",
  "config_id": "kubewaf/shop/shop-waf",
  "allow_fallback": false,
  "default_directives": "default",
  "directives_map": {
    "default": [
      "Include @kubewaf-defaults",
      "SecRuleEngine On",
      "SecDebugLogLevel 3",
      "Include @crs-setup-conf",
      "Include @owasp_crs/*.conf"
    ]
  },
  "metric_labels": {
    "waf_namespace": "shop",
    "waf_name": "shop-waf",
    "engine": "modsecurity",
    "owner": "modsecurity-proxy-wasm"
  },
  "metrics": {
    "enabled": true,
    "per_rule_id": true,
    "rule_tags": true
  },
  "block": {
    "message": "Forbidden",
    "blocked_header": "x-blocked",
    "add_rule_id_header": false,
    "rule_id_header": "x-blocked-rule-id",
    "add_request_id_header": false,
    "request_id_header": "x-request-id"
  },
  "data_files": {
    "team-scanners.data": "<base64 body>",
    "scanners-user-agents.data": "<base64 body>"
  },
  "data_files_encoding": "base64"
}
```

Client-facing deny responses are **product-neutral by default** (no vendor/product names in
body or headers).

| Field | Notes |
|-------|--------|
| `mode` | `kubewaf` enables fail-closed behaviour (no silent fallback) |
| `config_id` | Stable identity for logs / metrics |
| `directives_map` / `default_directives` | Named SecLang profiles |
| `allow_fallback` | When false (kubeWAF default), invalid config aborts startup |
| `metric_labels` | Name-embedded Prometheus labels |
| `metrics` | Per-rule / tag series toggles |
| `block.message` | Body/message for blocked responses (default `Forbidden`) |
| `block.blocked_header` | Generic marker header (default `x-blocked`; empty omits it) |
| `block.add_rule_id_header` | When true, add the disrupting rule id on deny local-replies |
| `block.rule_id_header` | Header name for the rule id (default `x-blocked-rule-id`) |
| `block.add_request_id_header` | When true, add the correlated request id on deny local-replies |
| `block.request_id_header` | Header name for the request id (default `x-request-id`) |
| `data_files` | Basename → body map for `@pmFromFile` / `@ipMatchFromFile` (kubeWAF injects PhraseList, IPList, and stock CRS pack) |
| `data_files_encoding` | Encoding of values (`base64` default) |

Via the WAF CRD (`spec.block`), the same knobs are:

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
spec:
  block:
    message: Forbidden
    addBlockedHeader: true
    blockedHeader: x-blocked
    addRequestIDHeader: true
    requestIDHeader: x-request-id
```

Schema in the operator repo:
[waf-plugin-config.json](https://github.com/kubewaf-io/kubewaf/blob/main/schemas/waf-plugin-config.json).

---

## data_files (phrase / IP lists)

Path-b builds resolve `@pmFromFile` / `@ipMatchFromFile` basenames from a
configure-time **runtime map** (`data_files`) before any embedded CRS catalog.
kubeWAF always populates that map for ModSecurity WAFs:

- Stock CRS `*.data` from the operator pack  
- Custom [PhraseList](/docs/reference/crds/phraselist/) bodies (`@pmFromFile`)  
- Custom [IPList](/docs/reference/crds/iplist/) bodies (`@ipMatchFromFile`)  

Guide: [Phrase & IP lists](/docs/users/data-files/).

---

## Virtual includes (embedded CRS)

CRS and helpers are baked into the wasm; load them with virtual includes (no
runtime filesystem):

| Include | Purpose |
|---------|---------|
| `@kubewaf-defaults` | Production body access / tmp dirs |
| `@demo-conf` | Standalone demo overlay |
| `@crs-setup-conf` | CRS setup |
| `@owasp_crs/*.conf` | Full CRS rules |

Example CRS-only profile:

```json
{
  "directives_map": {
    "crs": [
      "Include @kubewaf-defaults",
      "SecRuleEngine On",
      "Include @crs-setup-conf",
      "Include @owasp_crs/*.conf"
    ]
  },
  "default_directives": "crs"
}
```

---

## Metrics

Core series are dual-emitted as `modsecurity_proxy_wasm.*` and `kubewaf_waf.*`.

```bash
curl -s http://127.0.0.1:9901/stats/prometheus | grep -E 'modsecurity_proxy_wasm|kubewaf_waf'
```

## Security logs

Every plugin log line is a single JSON object (no text prefix). Lifecycle events use
`"event":"version"|"configure_start"|"config_applied"|…`; security events use
`"event":"rule_match"` / `"tx_interrupt"`. Rule IDs appear as both `"id"` (go-ftw)
and `"rule_id"`.

```text
{"component":"modsecurity-proxy-wasm","event":"rule_match","engine":"modsecurity","id":942100,"rule_id":942100,"phase":2,"severity":2,"disruptive":false,"msg":"..."}
{"component":"modsecurity-proxy-wasm","event":"tx_interrupt","engine":"modsecurity","config_id":"kubewaf/shop/shop-waf","id":949110,"rule_id":949110,"disruptive":true}
{"component":"modsecurity-proxy-wasm","event":"config_applied","config_id":"kubewaf/shop/shop-waf","mode":"kubewaf","stats":true}
```

---

## Related

- [Standalone Envoy](standalone/)  
- [kubeWAF WAF engine guide](/docs/platform/engine/)  
- [Upstream repository](https://github.com/kubewaf-io/modsecurity-proxy-wasm)  
