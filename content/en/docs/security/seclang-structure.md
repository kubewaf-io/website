---

title: "SecLang YAML Structure"
description: "Structured SecLang representation used by kubeWAF CRDs"
weight: 20
content_type: reference
aliases:
  - "/docs/reference/seclang-structure/"
  - "/docs/kubewaf/reference/seclang-structure/"
---
Prefer the one-rule form on `SecRule`: `spec.metadata` + `spec.match[]` +
`spec.actions`. `match[]` uses the same condition shape as the bag below.

`spec.secLangRules[]` is the multi-rule bag (CRS samples). Fields here apply to
both.

## One-rule form

```yaml
spec:
  order: 100001
  markerAfter: END-CUSTOM
  metadata: SecRuleMetadata
  match: []Condition        # length > 1 = chain
  actions: SecRuleActions
```

## Multi-rule bag (`secLangRules[]`)

```yaml
- metadata: SecRuleMetadata
  conditions: []Condition
  actions: SecRuleActions
  chainedRule: bool
  secMarker: string
```

## Metadata

```yaml
metadata:
  id: 942100
  phase: "2"
  message: "SQL Injection Attack Detected"
  severity: CRITICAL
  tags:
    - attack-sqli
    - OWASP_CRS
    - paranoia-level/2
```

Supported severities: `EMERGENCY`, `ALERT`, `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFO`, `DEBUG`.

## Conditions

A condition describes **when** the rule should trigger.

### Variable Form

```yaml
conditions:
- variables:
  - name: REQUEST_URI
  collections:
  - name: ARGS_GET
    arguments: [id]
  operator:
    name: rx
    value: (?:union|select|--)
    negate: false
```

### Collection / TX Form (common in CRS)

```yaml
conditions:
- collections:
  - name: TX
    arguments:
    - DETECTION_PARANOIA_LEVEL
  operator:
    name: lt
    value: "1"
```

### Always-Match (initialization rules)

```yaml
conditions:
- always-match: true
```

## Operators

| Name                | Example Value          | Notes |
|---------------------|------------------------|-------|
| `rx`                | `(?i)select.*from`     | Most common |
| `strEq`, `contains`, `beginsWith`, `endsWith` | `admin` | String ops |
| `eq`, `gt`, `ge`, `lt`, `le` | `5` | Numeric |
| `ipMatch`           | `192.168.0.0/16,10.0.0.0/8` | |
| `pm` / `pmFromFile` | `team-scanners.data`   | File body from [PhraseList](/docs/reference/crds/phraselist/) |
| `ipMatchFromFile`   | `edge-ip-blocklist.data` | File body from [IPList](/docs/reference/crds/iplist/) |
| `detectSQLi`        | (no value)             | Uses libinjection |
| `detectXSS`         | (no value)             | |
| `geoLookup`         | (no value)             | Requires GeoIP data in Wasm image |

## Actions

### Disruptive Actions

These decide whether the request continues:

```yaml
disruptive:
  disruptiveActionType: deny    # redirect uses value: <url>
data:
- dataActionType: status
  value: "403"
```

### Flow Control

```yaml
flow:
- flowActionType: skip
  value: "5"                # skip the next N rules
- flowActionType: skipAfter
  value: END-REQUEST-920    # skip to marker
```

### Non-Disruptive Actions

These modify state or logging without stopping evaluation:

```yaml
non-disruptive:
- nonDisruptiveActionType: setvar
  value: TX.inbound_anomaly_score_pl1=+5
- nonDisruptiveActionType: logdata
  value: "%{MATCHED_VAR}"
- nonDisruptiveActionType: ctl
  value: ruleRemoveById=942100
- nonDisruptiveActionType: nolog
```

Log text is `metadata.message`. There is no `msg` action type.

## Chaining

To express "condition A AND condition B":

```yaml
- metadata: { id: 942100, ... }
  conditions: [ condition A ]
  actions:
    disruptive: { disruptiveActionType: pass }
  chainedRule: true
- metadata: { ... same id ... }
  conditions: [ condition B ]
  actions:
    disruptive: { disruptiveActionType: block }
```

The converter automatically emits the `chain` action on the first part.

## SecMarker

A marker rule looks like this:

```yaml
- secMarker: END-REQUEST-920-PROTOCOL-ENFORCEMENT
  metadata:
    id: 0
    phase: "1"
  conditions:
  - always-match: true
  actions:
    non-disruptive:
    - nonDisruptiveActionType: nolog
```

Later rules can `skipAfter: END-REQUEST-920-PROTOCOL-ENFORCEMENT`.

## Complete Realistic Example

See the CRS samples in the repository (`config/samples/crs/`) — they are the best reference for complex real-world rules including heavy use of `TX` variables, `ctl` actions, and chaining.

## Conversion Guarantees

The controller uses the same `crslang` library that the CRS converter uses. The generated `.status.secRuleString` is what the WAF engine compiles (modsecurity-proxy-wasm).

If you ever want to debug "why isn't my rule matching?", copy the `secRuleString` value and exercise it against a local Envoy + modsecurity-proxy-wasm setup (see that module’s tests).

## Full CRD Schema

For every possible field and validation rule, see the generated CRD:

- [seclang.kubewaf.io_secrules.yaml](https://github.com/kubewaf-io/kubewaf/blob/main/config/crd/bases/seclang.kubewaf.io_secrules.yaml)

Next: read the [Troubleshooting](/docs/platform/troubleshooting) page.