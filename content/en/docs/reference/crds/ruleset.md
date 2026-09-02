---
title: "RuleSet"
description: "RuleSet custom resource reference"
weight: 20
content_type: reference
---
**Group**: `waf.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `RuleSet`  
**Short name**: `rs`

## Purpose

A `RuleSet` aggregates one or more `SecRule` / `SecAction` (or other RuleSets) into a named, reusable policy unit that can be attached to gateways.

## Spec

```yaml
spec:
  ruleRefs: []RuleRef
  allowedRules: RuleNamespaces
  phraseListRefs: []PhraseListLocalRef   # optional packaging
  ipListRefs: []IPListLocalRef           # optional packaging
```

### RuleRef

| Field      | Description |
|------------|-------------|
| `kind`     | `SecRule`, `SecAction`, `RuleSet`, or `ConfigMap` (future) |
| `name`     | Direct name reference (mutually exclusive with `selector`) |
| `namespace`| Defaults to the RuleSet's namespace |
| `group`    | API group (e.g. `seclang.kubewaf.io`, `waf.kubewaf.io`) |
| `version`  | API version (`v1beta1`) |
| `selector` | Label selector (mutually exclusive with `name`) |

**Constraint**: Exactly one of `name` or `selector` must be present (enforced by CEL validation on the CRD).

### AllowedRules / RuleNamespaces

```yaml
allowedRules:
  from: Same | All | Selector
  selector:      # only when from=Selector
    matchLabels:
      security: trusted
```

This controls **which namespaces** the RuleSet is allowed to pull rules from.

### phraseListRefs / ipListRefs

Optional same-namespace packaging for [PhraseList](../phraselist/) and [IPList](../iplist/).

| Field | Meaning |
|-------|---------|
| `phraseListRefs[].name` | PhraseList must exist and be Ready |
| `ipListRefs[].name` | IPList must exist and be Ready |

These are **presence checks only** — they do not inject unused list bodies into
plugin `data_files`. Injection is driven by basenames appearing in assembled
SecLang (`@pmFromFile` / `@ipMatchFromFile`). See [Phrase & IP lists](/docs/users/data-files/).

```yaml
spec:
  phraseListRefs:
    - name: team-scanners
  ipListRefs:
    - name: edge-ip-blocklist
```

## Status

```yaml
status:
  conditions:
  - type: ReferencesResolved
    status: "True"
  rulesLoaded: 12
  actionsLoaded: 2
  ruleRefs:
  - kind: SecRule
    name: block-sqlmap
    namespace: shop
```

| Field | Meaning |
|-------|---------|
| `rulesLoaded` | Count of resolved `SecRule` objects |
| `actionsLoaded` | Count of resolved `SecAction` objects |
| `ruleRefs` | Flattened member list (best-effort for selectors) |

```bash
kubectl get ruleset
# Resolved  Rules  Age
```

## Example

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: RuleSet
metadata:
  name: payment-protection
  namespace: platform
spec:
  ruleRefs:
  - kind: SecRule
    selector:
      matchLabels:
        waf.kubewaf.io/team: payments
  allowedRules:
    from: Same
```

## Important Semantics

- RuleSets are **recursive** — referencing another RuleSet is allowed and will be expanded.
- Direct `SecRule` references from `WAF` are **rejected** at the resolver level. You must go through a RuleSet.
- Changing a RuleSet automatically affects every `WAF` that references it (after the next reconciliation).

## Deletion & Finalizers

RuleSets use finalizers to maintain back-references on the rules they reference. Deleting a RuleSet is safe; the referenced rules are not deleted.

## See Also

- [Using RuleSets](/docs/users/rulesets/)
- [Phrase & IP lists](/docs/users/data-files/)
- [RuleSet types.go](https://github.com/kubewaf-io/kubewaf/blob/main/api/waf/v1beta1/ruleset_types.go)