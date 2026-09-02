---

title: "Writing Security Rules"
description: "Author ModSecurity-compatible SecRules as Kubernetes resources"
weight: 10
content_type: task
aliases:
  - "/docs/tasks/writing-rules/"
  - "/docs/operator/writing-rules/"
  - "/docs/kubewaf/operator/writing-rules/"
---
# Writing Security Rules

This guide teaches you how to write effective `SecRule` resources in kubeWAF.

## The Structured Format

Instead of writing raw SecLang strings, kubeWAF uses a typed Kubernetes representation. This gives you:

- OpenAPI on the CRD plus [validating webhooks](/docs/platform/webhooks/)
- Better IDE support and GitOps reviewability
- Automatic conversion to valid ModSecurity SecLang syntax

Prefer **one logical rule per `SecRule` CR** using:

```text
spec.metadata + spec.match[] + spec.actions  [+ order / markerAfter]
```

`spec.secLangRules[]` (multi-rule bag) is still accepted for bulk CRS samples.

## Minimal Example (canonical form)

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecRule
metadata:
  name: block-admin-bruteforce
  namespace: production
spec:
  order: 200010
  metadata:
    id: 200010
    phase: "2"
    message: "Multiple failed admin logins"
    severity: "WARNING"
    tags:
      - "attack-bruteforce"
      - "OWASP_CRS"
  match:
  - variables:
    - name: REQUEST_URI
    operator:
      name: rx
      value: ^/admin/login
  - collections:
    - name: ARGS_POST
      arguments: [password]
    operator:
      name: rx
      value: (?:admin|root)
  actions:
    disruptive:
      disruptiveActionType: pass   # scoring rule, not blocking
    non-disruptive:
    - nonDisruptiveActionType: setvar
      value: TX.anomaly_score_pl1=+3
```

`match[]` length > 1 is a **chain** (AND): the converter injects the `chain` flow action on every link except the last.

## Anatomy of a Rule

### metadata

Rule metadata lives under **`spec.metadata`** (not Kubernetes object metadata).

| Field      | Description                                      | Example          |
|------------|--------------------------------------------------|------------------|
| `id`       | Unique numeric rule ID. **Optional** for custom rules: omit it and the controller allocates from the cluster `SecRuleIDPool` (default `100000`–`999999`). Use fixed ids for CRS / shared rules. | `920100` or omit |
| `phase`    | Execution phase (`1`–`5`)                        | `"2"`            |
| `message`  | Human-readable description shown in logs         | "SQL Injection"  |
| `severity` | `EMERGENCY`, `ALERT`, `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFO`, `DEBUG` | `ERROR` |
| `tags`     | Classification tags (also mirrored to CR labels) | `["attack-sqli"]` |

### order and markerAfter

| Field | Description |
|-------|-------------|
| `order` | Relative sort key when RuleSets expand many SecRules (mirrored as `seclang.kubewaf.io/order`). Often set to the rule id. |
| `markerAfter` | Emits `SecMarker <name>` **after** this rule (target for earlier `skipAfter` actions). |

#### Auto IDs (`SecRuleIDPool`)

When `metadata.id` is omitted or `0`, the leader allocates a cluster-unique id from the
singleton pool `SecRuleIDPool/cluster` and writes:

- `status.ruleId` / `status.assignedIds` — effective ids used in rendered SecLang
- `status.idSource` — `Spec`, `Auto`, or `Mixed`
- label `seclang.kubewaf.io/id` and sticky annotation `seclang.kubewaf.io/assigned-id`

You normally do not create the pool by hand; the operator creates it with defaults on first allocation. To pin a range:

```yaml
apiVersion: seclang.kubewaf.io/v1beta1
kind: SecRuleIDPool
metadata:
  name: cluster
spec:
  minId: 100000
  maxId: 999999
```

#### Tags as labels

Each `metadata.tags` entry is mirrored onto the SecRule object as
`seclang.kubewaf.io/tag.<sanitized>=true` (e.g. `OWASP_CRS` → `seclang.kubewaf.io/tag.owasp_crs=true`).
Use those labels in RuleSet / kubectl selectors. Tags remain in `spec` for SecLang output.

### match (conditions)

Each `match[]` entry is a combination of **variables** / **collections** + **operator**.

Supported styles:

```yaml
# Scalar variable
variables:
- name: REQUEST_URI

# Collection (all members)
collections:
- name: ARGS

# Collection member
collections:
- name: ARGS_POST
  arguments: [password]

# TX collection (transaction variables)
collections:
- name: TX
  arguments: [ANOMALY_SCORE]
```

### operators

Common operators:

- `rx` — regular expression (most powerful)
- `eq`, `gt`, `lt`, `ge`, `le`
- `strEq`, `beginsWith`, `endsWith`, `contains`
- `pm`, `pmFromFile` / `pmf` — phrase match (file body from [PhraseList](/docs/reference/crds/phraselist/))
- `ipMatch`, `ipMatchFromFile` / `ipMatchF` — IP/CIDR match (file body from [IPList](/docs/reference/crds/iplist/))
- `geoLookup`
- `detectSQLi`, `detectXSS` (from libinjection in the WAF engine)

Use `negate: true` to invert the match.

For `@pmFromFile` / `@ipMatchFromFile`, set `operator.value` to the list
`fileName` (e.g. `team-scanners.data`) and create a same-namespace PhraseList or
IPList. Details: [Phrase & IP lists](/docs/users/data-files/).

### actions

Actions are split into three groups in the CRD:

```yaml
actions:
  disruptive:
    disruptiveActionType: deny          # or allow, block, drop, pass, redirect
    # redirect: set disruptiveActionType: redirect and value: <url>
  data:
  - dataActionType: status
    value: "403"

  flow:
  - flowActionType: skip
    value: "5"                  # skip the next N rules
  - flowActionType: skipAfter
    value: END-REQUEST-920

  non-disruptive:
  - nonDisruptiveActionType: setvar
    value: TX.inbound_anomaly_score_pl1=+5
  - nonDisruptiveActionType: setvar
    value: tx.detection_paranoia_level=2
  - nonDisruptiveActionType: logdata
    value: "%{REQUEST_URI}"
  - nonDisruptiveActionType: log
```

Log text lives on `metadata.message`. There is no `msg` action type.

## Chained Rules (`match[]`)

Chained rules allow multi-condition logic (AND). Prefer **one CR** with multiple `match` entries:

```yaml
spec:
  metadata: { id: 942100, phase: "2", message: "..." }
  match:
  - collections: [{ name: ARGS }]
    operator: { name: rx, value: "(?i)select" }
    actions:
      non-disruptive:
      - nonDisruptiveActionType: capture
  - collections: [{ name: TX, arguments: ["0"] }]
    operator: { name: rx, value: ".+" }
  actions:
    disruptive: { disruptiveActionType: block }
```

The converter injects `chain` on every link except the last.

Legacy multi-rule bags still support `flow: [{ flowActionType: chain }]` across consecutive `secLangRules` entries (used by CRS bulk samples).

## SecMarker and Flow Control

Emit a marker **after** a rule with `markerAfter`:

```yaml
spec:
  markerAfter: END-REQUEST-920-PROTOCOL-ENFORCEMENT
  metadata: { id: 920460, phase: "1" }
  match:
  - always-match: true
  actions:
    non-disruptive:
    - nonDisruptiveActionType: nolog
```

Earlier rules can `skipAfter: END-REQUEST-920-PROTOCOL-ENFORCEMENT`.

## Best Practices

1. **Use high rule IDs** for your custom rules (> 100000 recommended) to avoid collisions with CRS.
2. **Tag everything** — makes it easy to create RuleSets with selectors later.
3. **Prefer anomaly scoring** over immediate `deny` for better false-positive handling.
4. **Write unit-test equivalents** — many teams create a small test HTTPRoute + curl matrix.
5. **Store rules in Git** alongside your application manifests (GitOps).

## Writing Rules with AI Assistance

The structured `SecRule` format is powerful for validation and GitOps, but it is verbose. kubeWAF makes it much easier to create high-quality rules by providing excellent support for AI coding assistants.

### Using AI to create SecRules

**If you use Grok** (the Grok TUI or CLI):

- A dedicated skill called `kubewaf-secrule` is automatically available when you are inside this repository.
- Just describe what you need in plain language:
  - "Create a SecRule that blocks suspicious User-Agents hitting login pages"
  - "Write a virtual patch for path traversal on /api/files"
  - "Convert this raw SecLang rule to the proper Kubernetes format and validate it"

The skill generates both raw SecLang and the full `kind: SecRule` YAML, validates it against the Kubernetes API server using `kubectl apply --dry-run=server`, and can fix issues automatically.

**If you use any other AI** (Claude, Cursor, GPT-4, Continue.dev, Aider, Windsurf, etc.):

1. Copy the [SecRule expert prompt](/docs/security/ai/kubewaf-secrule-expert/) into your conversation or project rules.
2. Many tools also load guidance from the operator repo `AGENTS.md`.

See [AI assistance](/docs/security/ai/).

### Recommended AI + Validation Workflow

1. Describe the desired protection in natural language.
2. Ask the AI to return **both** a raw SecLang version and the structured `SecRule` YAML.
3. **Always validate** the generated resource before using it:

   ```bash
   kubectl apply -f my-new-rule.yaml --dry-run=server
   ```

   This sends the object to the real API server and exercises the CRD schema (plus any validating webhooks).

4. Let the AI also generate a matching `RuleSet` that wires the new rule into your WAF policy.

This combination gives you the speed of natural language with the safety of proper Kubernetes validation.

## Converting Existing ModSecurity Rules

If you have existing `.conf` files in SecLang syntax, you can:

1. Use the `crs-converter` tool (see [OWASP CRS](/docs/security/using-crs/))
2. Or manually translate them into the structured YAML format

The converter produces high-fidelity `SecRule` objects that you can further edit.

## Validation & Status

After applying a `SecRule`, check its status:

```bash
kubectl get secrule block-bad-ua -o yaml
```

The `.status.secRuleString` field contains the exact SecLang that will be sent to modsecurity-proxy-wasm.

If conversion fails, the `Ready` condition will be `False` with a helpful message.

## Next

Now that you can write individual rules, learn how to [organize them with RuleSets](/docs/users/rulesets/).
Dry-run a request: [Probes](/docs/platform/observability/probes/).
