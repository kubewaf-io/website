---

title: "OWASP Core Rule Set (CRS)"
description: "Enable and tune the OWASP Core Rule Set with kubeWAF"
weight: 15
content_type: task
aliases:
  - "/docs/users/using-crs/"
  - "/docs/tasks/using-crs/"
  - "/docs/operator/using-crs/"
  - "/docs/kubewaf/operator/using-crs/"
---
# OWASP Core Rule Set (CRS)

The [OWASP Core Rule Set](https://coreruleset.org/) is the default baseline
kubeWAF can attach to a `WAF`. **Path B** (structured `SecRule` CRs via
`kubewaf-crs`) is the default. **Path A** (`crsEnable: true`) emits engine
virtual includes and needs the full-catalog wasm.

{{% alert title="Beta: start in DetectionOnly" color="warning" %}}
On first CRS attach, set `spec.mode: DetectionOnly` so you observe scores without
denying traffic. Flip to `Blocking` after tuning. See [Beta status](/docs/get-started/beta/)
and [WAF engine](/docs/platform/engine/).
{{% /alert %}}

## Two paths

| Path | What the operator emits | What you need |
|------|-------------------------|---------------|
| **B (default)** | Your RuleSet SecLang + optional `spec.crs` setup/exclusions | `kubewaf-crs` (or other SecRule RuleSets). Default operator wasm is path-b. |
| **A** | `Include @crs-setup-conf` + `Include @owasp_crs/*.conf` plus `spec.crs` | Full-catalog wasm (`*-full` / `make wasm-build-full`). Not the default image. |

`spec.crs` (paranoia, thresholds, remove-by-id/tag) applies on both paths. `crsEnable` is only the engine-include switch.

## Enabling CRS

### Path B — structured RuleSets (recommended for GitOps)

No engine `Include @owasp_crs`. Attach a RuleSet of SecRules (full CRS samples or an optimized profile) and optionally tune with `spec.crs` **without** `crsEnable`:

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: protect-api
spec:
  crsEnable: false
  crs:
    paranoiaLevel: 1
    inboundAnomalyThreshold: 5
    removeById: [942100]          # optional exclusions after loaded CRs
  ruleRefs:
  - kind: RuleSet
    name: ruleset-api               # or full CRS RuleSet
    group: waf.kubewaf.io
    version: v1beta1
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: my-app
```

Directive order (Path B): defaults → **setup SecAction** (`spec.crs`) → RuleSet SecLang → **exclusions**.

### Path A — engine includes

Only when the operator image embeds the **full** CRS catalog. Default path-b wasm
does not contain `@crs-setup-conf` / `@owasp_crs`.

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: protect-all
spec:
  crsEnable: true
  crs:
    paranoiaLevel: 2
  ruleRefs:
  - kind: RuleSet
    name: my-custom-rules
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: my-app
```

Custom rules and embedded CRS run together. Anomaly scoring sees scores from both.

## CRS Version & Samples

kubeWAF ships converted rules for **CRS v4.27.0** (aligned with
modsecurity-proxy-wasm’s embedded CRS). The **platform team** installs the
`kubewaf-crs` chart after the operator — see
[Installation](/docs/platform/installation/#crs-as-kubernetes-objects-optional).

That chart installs stock CRS `PhraseList`s and profile RuleSets. **On by
default:** `crs-core`, `ruleset-api`, `ruleset-backend` (plus extras).
`php`, `java`, `golang`, `dotnet`, and `frontend` are off until platform enables
them (`--set profiles.php.enabled=true`, …).

Re-convert newer releases with `bin/crs-converter` (see
[SecLang CRS gaps](/docs/contribute/seclang-crs-gaps/)).

The converted rules (and `config/samples/crs/` in the operator repo) are labeled:

```yaml
metadata:
  labels:
    app.kubernetes.io/part-of: coreruleset
    coreruleset/version: "4.27.0"
    coreruleset/file: REQUEST-920-PROTOCOL-ENFORCEMENT.conf
```

## Optimized stack RuleSets

Full CRS is thorough but CPU-heavy. For Path B (structured SecRules), kubeWAF
ships **profile RuleSets** that compose a shared core with only the CRS files
that matter for that stack:

| RuleSet | Default | Workload |
|---------|---------|----------|
| `crs-core` | on | Protocol, init, scanners, anomaly scoring (compose into others) |
| `ruleset-api` | on | JSON REST APIs (no XSS pack) |
| `ruleset-backend` | on | Language-agnostic backends |
| `ruleset-php` | off | PHP apps — `--set profiles.php.enabled=true` |
| `ruleset-java` | off | Java / Spring — `--set profiles.java.enabled=true` |
| `ruleset-golang` | off | Go — `--set profiles.golang.enabled=true` |
| `ruleset-dotnet` | off | ASP.NET — `--set profiles.dotnet.enabled=true` |
| `ruleset-frontend` | off | SPA / HTML UI — `--set profiles.frontend.enabled=true` |

From an operator checkout (platform usually does this, or you consume the Helm profiles):

```bash
kubectl apply -f config/samples/crs/          # SecRules
kubectl apply -f config/samples/crs/optimized-rulesets.yaml
```

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: payments-api
spec:
  crsEnable: false
  crs:
    paranoiaLevel: 1
    inboundAnomalyThreshold: 5
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: payments
  ruleRefs:
  - kind: RuleSet
    name: ruleset-api
    group: waf.kubewaf.io
    version: v1beta1
```

Details and inclusion tables: `config/samples/crs/README.md`. See also `config/samples/crs/waf-api.yaml`.

A convenient `RuleSet` that selects the entire CRS is also provided:

```yaml
# config/samples/crs/crs-ruleset.yaml
kind: RuleSet
metadata:
  name: ruleset-crs
spec:
  ruleRefs:
  - kind: SecRule
    namespace: default     # change as needed
    selector:
      matchLabels:
        coreruleset/version: "4.27.0"
```

You can reference this RuleSet or create your own selector-based one.

## Paranoia Levels & Thresholds

CRS v4 uses **paranoia levels** (1–4). Higher levels = more aggressive detection but higher chance of false positives.

The initialization rules (usually `REQUEST-901-INITIALIZATION`) set:

- `tx.detection_paranoia_level`
- `tx.inbound_anomaly_score_threshold`
- `tx.outbound_anomaly_score_threshold`

You can override these values with your own `SecRule` that runs early in phase 1 and sets the TX variables.

**Preferred for simple tuning: the declarative `crs:` block on the WAF**

kubeWAF supports **declarative CRS tuning** directly on the `WAF` resource.
Use this for paranoia, thresholds, and common false-positive exclusions because:

- The operator guarantees correct directive ordering: Path B is setup → RuleSet SecLang → exclusions. Path A inserts `Include @owasp_crs` before exclusions.
- No need to hand-author early `SecAction` / `SecRule` objects just for tuning.
- The intent is visible and reviewable at the WAF policy level.

Example:

```yaml
spec:
  crsEnable: false
  crs:
    paranoiaLevel: 2                 # sets both detection + blocking
    inboundAnomalyThreshold: 10
    outboundAnomalyThreshold: 5
    removeById: [942100, 941100]     # drop noisy rules entirely
    removeByTag: ["attack-php"]
    updateTargetById:                # surgical variable exclusions (most common FP fix)
      - id: 920273
        removeTargets: ["ARGS:json_blob"]
      - id: 942100
        removeTargets: ["ARGS:csrf_token", "REQUEST_COOKIES:sessionid"]
```

See `config/samples/waf_v1beta1_waf_crs_tuned.yaml` for a full example.

A phase-1 `SecRule` / `SecAction` with `setvar` still works when you need extra early logic.

## Using the CRS Converter Tool

If you want to upgrade to a newer CRS release or customize the conversion:

```bash
# Build the tool
make crs-converter

# Convert a full CRS checkout (default: one SecRule CR per logical rule)
bin/crs-converter \
  --input=/path/to/coreruleset/rules \
  --output-dir=config/samples/crs-new \
  --crs-version=4.4.0 \
  --namespace=platform-security \
  --mode=one

# Legacy multi-rule bag (one CR per .conf file with secLangRules[]):
bin/crs-converter ... --mode=bag
```

The tool (`-mode=one`, default):

- Parses the original `.conf` files using `crslang`
- Emits **one `SecRule` CR per logical rule** (canonical `metadata` + `match[]` + `actions`)
- Groups ModSecurity chains into a single CR (`match` length > 1)
- Sets `spec.order` from the rule id (RuleSet assembly sorts by order/id)
- Emits `spec.markerAfter` on the last rule of each group (skipAfter targets)
- Multi-document YAML per source file; labels: `coreruleset/file`, `coreruleset/version`, `seclang.kubewaf.io/id`, tags
- Use `-mode=bag` for the older one-CR-per-file packaging

## Mixing CRS with Custom Rules

RuleSet expansion sorts SecRules by `spec.order` (else rule id), then name.

A typical effective combination:

1. Early initialization rules (your overrides)
2. CRS rules (via `crsEnable` or explicit RuleSet)
3. Your own "allow-list" or "exception" rules (using `SecAction` + `ctl:ruleRemoveById`)
4. Final blocking / anomaly scoring rules

## Performance Considerations

CRS contains ~300–400 rules. Most of them are cheap regex or byte checks. On modern hardware the overhead per request is usually < 1–2 ms.

If you are extremely latency-sensitive:

- Start with paranoia level 1 + higher anomaly threshold
- Exclude rules you know are irrelevant (e.g., PHP-specific rules in a Java shop)
- Use `SecAction` + `ctl:ruleRemoveById` or `ctl:ruleRemoveByTag`

## Troubleshooting CRS

**Too many false positives?**

- Lower the paranoia level
- Raise the anomaly score threshold
- Add exclusion rules early

**Nothing is being blocked?**

- Path B: the profile RuleSet is referenced (`ruleset-api`, …)  
- Path A: `crsEnable: true` **and** full-catalog wasm
- Check the WAF logs (Envoy Gateway logs + WASM filter logs)
- Verify the `ReferencesResolved` condition on your `WAF`

**I want only part of CRS**

Create a custom RuleSet that selects only the files you care about:

```yaml
selector:
  matchExpressions:
  - key: coreruleset/file
    operator: In
    values: ["REQUEST-920-PROTOCOL-ENFORCEMENT.conf", "REQUEST-942-APPLICATION-ATTACK-SQLI.conf"]
```

## Further Reading

- [OWASP CRS Documentation](https://coreruleset.org/docs/)
- [CRS GitHub](https://github.com/coreruleset/coreruleset)
- [Paranoia Levels Explained](https://coreruleset.org/docs/2-how-crs-works/paranoia_levels/)

Next: [attach these rules on Envoy Gateway](/docs/platform/providers/envoy-gateway/).
