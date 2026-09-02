---
title: "SecAction"
description: "SecAction custom resource reference"
weight: 15
content_type: reference
---
**Group**: `seclang.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `SecAction`  
**Short name**: `sa`

## Purpose

`SecAction` is an unconditional SecLang action (no match). Use it for CRS
setup `setvar`s, `ctl` exclusions, or other always-run directives. Attach
through a [RuleSet](../ruleset/), not directly from a `WAF`.

## Example

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecAction
metadata:
  name: early-paranoia
spec:
  metadata:
    id: 900990
    phase: "1"
  non-disruptive:
  - nonDisruptiveActionType: setvar
    value: tx.detection_paranoia_level=1
```

A `WAF.spec.crs` block already emits setup and exclusion directives. You only
need a `SecAction` CR for extra early logic.

## Spec

| Field | Description |
|-------|-------------|
| `metadata` | id, phase, message, tags (same shape as SecRule) |
| `disruptive` / `flow` / `non-disruptive` | Actions (inlined) |
| `transformations` | Optional |

## Status

`secRuleString` is the rendered SecLang. `ruleSetRefs` lists owning RuleSets.

The [webhook](/docs/platform/webhooks/) requires metadata and/or actions.

## Related

- [SecRule](../secrule/)
- [Writing security rules](/docs/security/writing-rules/)
