---
title: "IPList"
description: "IPList custom resource reference — IP/CIDR bodies for @ipMatchFromFile"
weight: 45
content_type: reference
---

**Group**: `seclang.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `IPList`  
**Short name**: `ipl`  
**Scope**: Namespaced

## Purpose

`IPList` holds an **IP/CIDR list file body** for SecLang `@ipMatchFromFile` / `@ipMatchF`.
Content is injected via the same plugin `data_files` path as [PhraseList](../phraselist/)
(always enabled for ModSecurity). Use **PhraseList** for phrase tokens (`@pmFromFile`);
do not mix list kinds for the same basename.

## Example

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: IPList
metadata:
  name: edge-ip-blocklist
  labels:
    seclang.kubewaf.io/ip-list: "true"
spec:
  fileName: edge-ip-blocklist.data
  content: |
    # one IP or CIDR per line
    203.0.113.0/24
    198.51.100.50
    192.0.2.1
```

SecRule:

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecRule
metadata:
  name: block-edge-ip-list
spec:
  match:
    - collections:
        - name: REMOTE_ADDR
      operator:
        name: ipMatchFromFile
        value: edge-ip-blocklist.data
  metadata:
    id: 100002
    phase: "1"
    message: Edge IP blocklist
  actions:
    disruptive:
      disruptiveActionType: deny
```

## Spec

Exactly **one** of `content`, `configMapRef`, or `parts` is required.

| Field | Type | Description |
|-------|------|-------------|
| `fileName` | string | Basename used in SecLang (`*.data`). Required. |
| `content` | string | Inline body (max 768 KiB). One IP or CIDR per line; `#` comments allowed. |
| `configMapRef` | object | `{ name, key }` — same-namespace ConfigMap. |
| `parts` | array | Ordered ConfigMap segments (max 16, ≤ 2 MiB total). |

The validating webhook soft-warns when inline lines do not parse as IP/CIDR
(hard-fail is reserved for schema/source errors so bulk dumps stay usable).

## Status

| Field | Meaning |
|-------|---------|
| `conditions[type=Ready]` | Content resolved, size OK, no fileName conflict |
| `fileName` | Mirrors `spec.fileName` when Ready |
| `sizeBytes` | Composed body size |
| `contentHash` | SHA-256 hex of the body |

```bash
kubectl get iplist
# Ready  FileName  Size  Age
```

## Semantics

- **Same-namespace only** discovery with the WAF.
- **One Ready owner per `(namespace, fileName)`** — conflicts with another Ready IPList **or** PhraseList.
- Inject set = basenames in assembled SecLang (`@ipMatchFromFile` / `@ipMatchF`).
- Optional RuleSet packaging: `spec.ipListRefs` (presence/Ready check only).
- Missing custom basenames follow `WAF.spec.phraseListPolicy` (`FailClosed` / `IgnoreUnknown`).

## Related

- [PhraseList](../phraselist/) — phrase tokens for `@pmFromFile`
- [Phrase & IP lists guide](/docs/users/data-files/)
- [WAF `phraseListPolicy`](../waf/#phraselistpolicy)
- [RuleSet `ipListRefs`](../ruleset/)
