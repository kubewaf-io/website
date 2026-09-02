---
title: "PhraseList"
description: "PhraseList custom resource reference — phrase bodies for @pmFromFile"
weight: 40
content_type: reference
---

**Group**: `seclang.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `PhraseList`  
**Short name**: `pl`  
**Scope**: Namespaced

## Purpose

`PhraseList` holds a **phrase-list file body** for SecLang `@pmFromFile` / `@pmf`.
The operator injects the composed body into the ModSecurity plugin config as
`data_files` (always enabled). Stock OWASP CRS `*.data` files are still
embedded in the operator/wasm pack; use PhraseList for **custom** basenames
(or annotated CRS overrides).

For IP/CIDR blocklists use [**IPList**](../iplist/) with `@ipMatchFromFile` instead.

## Example

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: PhraseList
metadata:
  name: team-scanners
  labels:
    seclang.kubewaf.io/phrase-list: "true"
spec:
  fileName: team-scanners.data
  content: |
    # one phrase per line
    evil-scanner-bot
    internal-recon-tool
```

SecRule (same namespace as the WAF):

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecRule
metadata:
  name: block-team-scanners
spec:
  match:
    - collections:
        - name: REQUEST_HEADERS
          arguments: [User-Agent]
      operator:
        name: pmFromFile
        value: team-scanners.data   # == PhraseList.spec.fileName
  metadata:
    id: 100001
    phase: "1"
    message: Team scanner UA
  actions:
    disruptive:
      disruptiveActionType: deny
```

## Spec

Exactly **one** of `content`, `configMapRef`, or `parts` is required (CEL + webhook).

| Field | Type | Description |
|-------|------|-------------|
| `fileName` | string | Basename used in SecLang (`*.data`). Required. Pattern: alphanumerics, `._-`, ends with `.data`. |
| `content` | string | Inline body (max 768 KiB). Newline-separated phrases; `#` comments allowed. |
| `configMapRef` | object | `{ name, key }` — single ConfigMap key in the **same namespace**. |
| `parts` | array | Ordered list of ConfigMap refs to compose large lists (max 16 parts, ≤ 2 MiB total). |

```yaml
spec:
  fileName: team-scanners.data
  # content: |
  #   phrase-a
  # configMapRef:
  #   name: scanner-phrases
  #   key: list.txt
  # parts:
  #   - configMapRef: { name: part-a, key: data }
  #   - configMapRef: { name: part-b, key: data }
```

## CRS override

To replace a **stock CRS** basename with a PhraseList body, set:

```yaml
metadata:
  annotations:
    seclang.kubewaf.io/allow-crs-override: "true"
```

Without the annotation the WAF refuses publish (`CRSOverrideNotAllowed`).

## Status

| Field | Meaning |
|-------|---------|
| `conditions[type=Ready]` | Content resolved, size OK, no fileName conflict |
| `fileName` | Mirrors `spec.fileName` when Ready |
| `sizeBytes` | Composed body size |
| `contentHash` | SHA-256 hex of the body |

```bash
kubectl get phraselist
# Ready  FileName  Size  Age
```

## Semantics

- **Same-namespace only**: discovery is scoped to the WAF namespace.
- **One Ready owner per `(namespace, fileName)`** across PhraseList **and** IPList.
- Composed body budget: **2 MiB** (aligned with inject budget).
- Inject set = basenames referenced in assembled SecLang (`@pmFromFile` / `@pmf`), not every packaged ref.
- Optional RuleSet packaging: `spec.phraseListRefs` (presence/Ready check only).

## Related

- [IPList](../iplist/) — IP/CIDR lists for `@ipMatchFromFile`
- [Phrase & IP lists guide](/docs/users/data-files/)
- [WAF `phraseListPolicy`](../waf/#phraselistpolicy)
- [RuleSet `phraseListRefs`](../ruleset/)
