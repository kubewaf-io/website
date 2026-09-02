---
title: "SecRuleIDPool"
description: "Cluster-scoped auto ID allocator for SecRules"
weight: 18
content_type: reference
---
**Group**: `seclang.kubewaf.io`  
**Version**: `v1beta1`  
**Kind**: `SecRuleIDPool`  
**Short name**: `sridpool`  
**Scope**: Cluster

## Purpose

When a `SecRule` omits `metadata.id` (or sets `0`), the leader allocates a
cluster-unique id from the singleton **`SecRuleIDPool/cluster`**.

You do not create the pool for normal use. The operator creates it on first
allocation with defaults `minId: 100000`, `maxId: 999999` (above CRS).

## Pin a range

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecRuleIDPool
metadata:
  name: cluster
spec:
  minId: 100000
  maxId: 999999
```

Only the object named `cluster` is used. Only the leader advances `status.nextId`.

## Status

| Field | Meaning |
|-------|---------|
| `nextId` | Next candidate |
| `lastAllocatedId` | Last grant |
| `allocatedCount` | Successful allocations (not live occupancy) |

The SecRule then shows `status.ruleId`, `status.assignedIds`, `status.idSource: Auto`,
and label `seclang.kubewaf.io/id`.

## Related

- [SecRule](../secrule/)
- [Writing security rules](/docs/security/writing-rules/#auto-ids-secruleidpool)
