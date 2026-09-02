---

title: "SecLang CRS Gaps"
description: "Structured seclang API vs full OWASP CRS — gap analysis"
weight: 20
content_type: reference
aliases:
  - "/docs/reference/seclang-crs-gaps/"
---
# seclang API vs full OWASP CRS — gap analysis

This document tracks what is needed for the **structured seclang API**
(`SecRule` / `SecAction` CRs) to faithfully represent the whole OWASP Core Rule
Set, versus how CRS actually runs in production today.

## Two CRS paths

| Path | Mechanism | Uses seclang API? |
|------|-----------|-------------------|
| **A. Engine include** | `WAF.spec.crsEnable: true` → `Include @crs-setup-conf` + `Include @owasp_crs/*.conf` | No |
| **B. Structured CRs (preferred for GitOps)** | `crsEnable: false` + RuleSet of SecRules; optional `spec.crs` tuning | Yes |

**Path B** is the target for full kube-native CRS. **Path A** remains an escape hatch / FTW bulk load.  
`spec.crs` applies on Path A and Path B (`crsEnable` is not required for tuning).

---

## What already works

- Large variable / collection / operator / action enums aligned with crslang.
- Chaining (`chain`), `skip` / `skipAfter`, `secMarker`.
- `setvar`, `ctl`, `capture`, scoring-style rules (in samples).
- Declarative tuning on `WAF.spec.crs` (paranoia, thresholds, remove by id/tag, update target by id) as **raw directives**:
  - Path A: after engine includes
  - Path B: setup SecAction **before** RuleSet SecLang; exclusions **after** RuleSet SecLang
- Samples under `config/samples/crs/` (~626 rule IDs, main REQUEST/RESPONSE files, labeled **CRS 4.27.0** to match the embedded engine).
- Optimized stack RuleSets (`ruleset-api`, `ruleset-php`, …) for selective Path B.
- **Compressed plugin config** (ModSecurity): large `directives_map` payloads use
  `directives_encoding: gzip+base64` so ECDS size stays small; wasm inflates on configure.
- **Path B e2e / go-ftw** harness: `make test-e2e-ftw-path-b` (`E2E_FTW_PATH_B=true`) applies
  `config/samples/crs` SecRules + RuleSet `ftw-crs-path-b` with `crsEnable: false`.

---

## Gap backlog

### P0 — converter fidelity (must fix for usable structured CRS)

| ID | Gap | Status | Notes |
|----|-----|--------|-------|
| P0-1 | `always-match` / SecAction maps to `operator.name: unknownOperator` | **Fixed** in convert + samples | Use `unconditionalMatch` when `AlwaysMatch` |
| P0-2 | `t:` transformations dropped on CRS → CR conversion | **Fixed** in convert + samples | Copy `Condition.Transformations` via mapper |
| P0-3 | Sample CRS version lag (was 4.3.0) | **Fixed** | Re-converted against **v4.27.0** (engine-aligned) |

### P1 — API / packaging completeness

| ID | Gap | Status | Notes |
|----|-----|--------|-------|
| P1-1 | No `accuracy` metadata field | Open | CRS uses accuracy 1–9; crslang metadata also lacks it |
| P1-2 | crs-converter always emits `kind: SecRule` for SecActions | Partial | Dataplane loads `SecAction` CRs via RuleSet; converter still emits SecRule for always-match CRS rows |
| P1-3 | `REQUEST-900` / exclusion templates are `.example` only in CRS 4.27 | N/A | Not shipped as active conf; user exclusions via `WAF.spec.crs` |
| P1-4 | `.data` files for `@pmFromFile` / `@ipMatchFromFile` not modeled | **Done** | **Path B:** stock CRS `.data` is wasm-embedded / operator-pack injected; custom phrases use **PhraseList**, IPs/CIDRs use **IPList**; both inject plugin `data_files`. Operator SecRule Ready validation uses `WithRootFS` + go:embed CRS pack. See [Phrase & IP lists](/docs/users/data-files/) and design `docs/design/pmfromfile-phraselist-api-to-wasm.md`. |
| P1-5 | ~~Sample CRS version vs engine~~ | Done | Samples = **4.27.0** |
| P1-6 | `REQUEST-912` DoS rules | N/A for 4.27 | Removed/not present as standalone conf in CRS 4.27.0 `rules/` |

### P2 — config directives & admin SecLang

| ID | Gap | Status | Notes |
|----|-----|--------|-------|
| P2-1 | No CR for `SecDefaultAction`, `SecRuleEngine`, body/audit limits | Open | Handled by engine defaults / WAF |
| P2-2 | `SecRuleUpdateActionById`, remove by msg | Open | Extend `WAF.spec.crs` or seclang CRs |
| P2-3 | Full `crs-setup.conf` as resources | Open | Path A uses `@crs-setup-conf` |
| P2-4 | Multi-level chain golden tests vs upstream CRS | Open | Converter attaches one chain hop |

---

## Operator mapping reference (targetRef discovery is separate)

CRS *rules* are independent of Gateway provider. Provider auto-discovery is documented in
`status.provider` / `status.providerDetection`.

---

## Recommended usage

```yaml
# Path B — structured CRS (no engine Include @owasp_crs)
spec:
  crsEnable: false
  crs:
    paranoiaLevel: 2
    inboundAnomalyThreshold: 5
    removeById: [942100]
  targetRef: { kind: Gateway, name: demo-gateway, group: gateway.networking.k8s.io }
  ruleRefs:
  - kind: RuleSet
    name: ruleset-api   # or full CRS / ruleset-php / ...
    group: waf.kubewaf.io
    version: v1beta1
```

```yaml
# Path A — engine-embedded includes
spec:
  crsEnable: true
  crs:
    paranoiaLevel: 2
    removeById: [942100]
  targetRef: { kind: Gateway, name: demo-gateway, group: gateway.networking.k8s.io }
  ruleRefs: [{ kind: RuleSet, name: my-custom-rules, ... }]
```

---

## Regenerating structured CRS samples

```bash
make crs-converter
# Point -input at a CRS rules/ directory (conf files only)
bin/crs-converter \
  -input=/path/to/coreruleset/rules \
  -output-dir=config/samples/crs \
  -crs-version=4.x.y \
  -namespace=default
```

Samples were re-converted from **CRS v4.27.0** (2026-07) and show:

- `operator.name: unconditionalMatch` on always-match rules (7 rules)  
- `transformations:` present in 25/26 rule files (~320 transform entries)

---

## Related code

| Area | Path |
|------|------|
| Types | `api/seclang/v1beta1/` |
| Convert | `api/seclang/v1beta1/convert/` |
| CRS → CR tool | `cmd/crs-converter/` |
| Path A includes | `internal/dataplane/config/build.go` (`BuildDirectives`, `CRSSetupActions`, `CRSExclusions`) |
| Samples | `config/samples/crs/` |
