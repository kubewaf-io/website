---
title: "SecRule"
description: "SecRule custom resource reference"
weight: 10
content_type: reference
---
**Group**: `seclang.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `SecRule`  
**Short name**: `sr`

## Purpose

`SecRule` is one logical ModSecurity rule as structured YAML. Prefer one CR per
rule: `spec.metadata` + `spec.match[]` + `spec.actions`.

`spec.secLangRules[]` (multi-rule bag) is still accepted for bulk CRS samples.
If `match` or top-level `metadata` is set, the bag is ignored.

Guide: [Writing security rules](/docs/security/writing-rules/).

## Example

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecRule
metadata:
  name: block-trace
  labels:
    app: demo-waf
spec:
  order: 100001
  metadata:
    id: 100001          # omit to allocate from SecRuleIDPool/cluster
    phase: "1"
    message: "TRACE method"
    severity: ERROR
  match:
  - variables:
    - name: REQUEST_METHOD
    operator:
      name: strEq
      value: "TRACE"
  actions:
    disruptive:
      disruptiveActionType: deny
    data:
    - dataActionType: status
      value: "403"
```

`match[]` length > 1 is a chain (AND). See [SecLang structure](/docs/security/seclang-structure/).

## Spec

| Field | Description |
|-------|-------------|
| `order` | Sort key when a RuleSet expands many SecRules |
| `markerAfter` | Emits `SecMarker` after this rule (`skipAfter` target) |
| `metadata` | id, phase, message, severity, tags |
| `match[]` | Conditions (variables / collections + operator) |
| `actions` | Disruptive / flow / non-disruptive |
| `secLangRules[]` | Multi-rule bag (CRS samples) |

Omit `metadata.id` (or set `0`) to allocate from [SecRuleIDPool](../secruleidpool/).

## Status

| Field | Meaning |
|-------|---------|
| `conditions[Ready]` | Rendered SecLang is valid |
| `secRuleString` | Emitted SecLang (what the engine receives) |
| `ruleId` / `assignedIds` | Effective id(s) |
| `idSource` | `Spec`, `Auto`, or `Mixed` |
| `ruleSetRefs` | RuleSets that include this rule |

```bash
kubectl get secrule
# Ready  RuleID  IDSource  Order  Age
```

## Validation

The [validating webhook](/docs/platform/webhooks/) checks match shape, phase 1–5,
and warns when `id` ≤ 100000 (CRS range).

## RBAC

Aggregated ClusterRoles: `secrule-viewer`, `secrule-editor`, `secrule-admin`.

Full schema: [seclang.kubewaf.io_secrules.yaml](https://github.com/kubewaf-io/kubewaf/blob/main/config/crd/bases/seclang.kubewaf.io_secrules.yaml).