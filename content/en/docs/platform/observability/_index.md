---
title: Observability
linkTitle: Observability
weight: 50
description: >
  Metrics, request capture, eval traces, and rule probes.
content_type: concept
aliases:
  - /docs/tasks/observability/
  - /docs/operator/observability/
  - /docs/kubewaf/operator/observability/
---

kubeWAF observability is **opt-in**. Envoy is the OTLP client (cluster
`kubewaf_otel`: stats sink and, when a WAF is `Managed`, a second OTel access
logger). Wasm only annotates.

| Page | Use |
|------|-----|
| This page | Managed metrics, catalog, query API |
| [Capture](capture/) | Eval traces, filter-state capture, Headlamp Observe |
| [Probes](probes/) | Dry-run a request against a SecRule, RuleSet, or WAF |

Do not fill `EnvoyProxy.spec.telemetry`, Istio `Telemetry`, or Hubble. Merge
kubeWAF bootstrap patches into the existing ECDS `EnvoyProxy` / Istio override
(same class as `kubewaf_ecds`).

## Enable the managed plane

`lite` = Collector + VictoriaMetrics (or Prometheus remote_write).
`full` = lite + VictoriaTraces (`waf.eval`): set `profile=full` **and**
`victoriaTraces.enabled` (or `victoriaTraces.endpoint`). Grafana is not part
of the managed plane.

Helm **fails** if managed is on and neither VictoriaMetrics (`enabled` or
`endpoint`) nor both `prometheusRemoteWrite.enabled` and
`prometheusRemoteWrite.endpoint` are set.

On an existing release (`--reuse-values` keeps webhooks, replicas, and prior
`--set`):

```bash
helm upgrade kubewaf oci://ghcr.io/kubewaf-io/charts/kubewaf \
  --namespace kubewaf-system \
  --version v0.1.0-beta.1 \
  --reuse-values \
  --set observability.managed.enabled=true \
  --set observability.managed.victoriaMetrics.enabled=true
```

First install: [Installation](/docs/platform/installation/), then the upgrade
above.

Then:

1. **Envoy Gateway:** add the `kubewaf_otel` cluster, OTel stats sink, and
   `stats_tags` JSONPatch ops from
   `config/samples/observability/bootstrap-envoyproxy-fragment.yaml` to the
   **same** `EnvoyProxy` that already has `kubewaf_ecds`
   ([bootstrap](/docs/platform/providers/envoy-gateway/#bootstrap-static-kubewaf_ecds-cluster-required)).
   Do not `kubectl apply` that sample as a second same-name object — it replaces
   the ECDS bootstrap and Envoy rejects the WAF filter.
2. **Istio:** merge the same cluster, sink, and tags into the existing ECDS
   bootstrap ConfigMap (`test/e2e/manifests/istio/ecds-bootstrap.yaml`).
3. Set `observability.managed.injectConfigured=true`.
4. On each WAF you want exported: `spec.telemetry.mode: Managed`.

Cilium remesh (`--otel-service`) writes STATIC `kubewaf_otel` and `stats_tags`
only. Cilium Envoy 1.19 does not load the OTel stats sink or a CEC access
logger — catalog OTLP and eval capture do not run. DIY `/stats` is separate.
See [Capture](capture/#cilium).

On Managed WAFs, condition `TelemetrySink` is Status True/False with Reason
`Ready`, `Degraded`, `Absent`, or `OTelClusterMissing` (Cilium remesh missing).
It does **not** gate `Ready`.

## Per-WAF policy

Metrics-only (`lite`). For traces, see [Capture](capture/).

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: shop-waf
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: shop-frontend
  ruleRefs:
    - kind: RuleSet
      name: shop-protection
  crsEnable: false
  telemetry:
    mode: Managed
  metrics:
    extraLabels:
      team: payments
    includeRuleID: true
    enableStats: true
```

| Field | Effect |
|-------|--------|
| `spec.telemetry.mode` | `None` (default) or `Managed` |
| `spec.telemetry.traces.enabled` | When unset: `lite` → false, `full` → true |
| `sampleRate` / `sampleDisruptive` | String in `0`–`1` (non-disruptive matches vs interrupts) |
| `redact` | Omit `client.address` from filter-state JSON (default true) |
| `includeMatchData` | Put match `data` on span events (default false) |
| `spec.metrics.enableStats` | ABI catalog on/off. `false` drops catalog series; traces can still export |
| `spec.metrics.includeRuleID` | Per-rule series |
| `spec.metrics.extraLabels` | Extra name-embedding keys. Cannot override `waf_namespace`, `waf_name`, `engine`, `owner` |

Plugin contract: [`schemas/waf-plugin-config.json`](https://github.com/kubewaf-io/kubewaf/blob/main/schemas/waf-plugin-config.json).

## Catalog

Product queries use `kubewaf.waf.*` / `kubewaf_waf_*` in VictoriaMetrics.
The filter dual-emits ABI series under `kubewaf_waf.*` and
`modsecurity_proxy_wasm.*`. The Envoy sink converts `kubewaf_waf.*` →
`kubewaf.waf.*` and DropAction-drops ABI twins. Collector `filter/waf_metrics`
is the membership gate (`kubewaf.waf.*`, `kubewaf_waf[._]*`, leftover
`modsecurity_proxy_wasm` / `wasmcustom`).

| Catalog (OTel) | Prom/VM | Attributes |
|----------------|---------|------------|
| `kubewaf.waf.tx.total` | `kubewaf_waf_tx_total` | identity |
| `kubewaf.waf.tx.allowed` | `kubewaf_waf_tx_allowed` | identity |
| `kubewaf.waf.tx.interruptions` | `kubewaf_waf_tx_interruptions` | + `phase` |
| `kubewaf.waf.tx.interruptions_by_rule` | `kubewaf_waf_tx_interruptions_by_rule` | + `phase`, `rule_id` |
| `kubewaf.waf.rule.matches` | `kubewaf_waf_rule_matches` | identity |
| `kubewaf.waf.rule.matches_by_phase` | `kubewaf_waf_rule_matches_by_phase` | + phase, severity |
| `kubewaf.waf.rule.matches_disruptive` | `kubewaf_waf_rule_matches_disruptive` | identity |
| `kubewaf.waf.rule.matches_by_rule` | `kubewaf_waf_rule_matches_by_rule` | + phase, `rule_id` |
| `kubewaf.waf.rule.matches_by_tag` | `kubewaf_waf_rule_matches_by_tag` | + phase, tag |
| `kubewaf.waf.memory.wasm_heap_bytes` | `kubewaf_waf_memory_wasm_heap_bytes` | identity |
| `kubewaf.waf.configure.fallback_rules` | `kubewaf_waf_configure_fallback_rules` | identity |

Identity labels: `waf_namespace`, `waf_name`, `engine` (`modsecurity`), `owner`.
Probe eval is go-coraza and is not this series.

Remote-write backends may add a `_total` suffix. Headlamp matches
`{__name__=~"kubewaf_waf_tx_total(_total)?"}`.

## Query API

Headlamp and `kubectl` read the catalog through `subresources.kubewaf.io` —
not `services/proxy` to VictoriaMetrics.

```bash
helm upgrade kubewaf oci://ghcr.io/kubewaf-io/charts/kubewaf \
  --namespace kubewaf-system \
  --version v0.1.0-beta.1 \
  --reuse-values \
  --set subresourceApi.enabled=true \
  --set subresourceApi.probes.enabled=false
```

`subresourceApi.query` defaults on. That `--set` turns probes **off** if they
were already on. To keep probes, set `probeTestServer.enabled=true` instead —
the chart fails if `probes.enabled` is true without the Test Server.

Directives (`GET …/wafs/{name}/directives`) default **off**. See [Probes](probes/).

Bind ClusterRole `<release>-query` (`get` on `wafs/metrics`, `wafs/traces`,
`wafs/directives`, `clustermetrics`). The API also SAR-`get`s the parent WAF.

```bash
kubectl proxy --port=8001 &

curl -sS \
  'http://127.0.0.1:8001/apis/subresources.kubewaf.io/v1alpha1/namespaces/shop/wafs/shop-waf/metrics?query=sum({__name__=~"kubewaf_waf_tx_total(_total)?"})'

curl -sS \
  'http://127.0.0.1:8001/apis/subresources.kubewaf.io/v1alpha1/clustermetrics?query=sum({__name__=~"kubewaf_waf_tx_interruptions(_total)?"})'
```

| Path | Role |
|------|------|
| `GET …/namespaces/{ns}/wafs/{name}/metrics?query=` | Instant PromQL, rewritten to that WAF |
| same + `start`/`end`/`step` | Range query (max 24h; step ≥ 15s) |
| `GET …/clustermetrics?query=` | Same, scoped to WAFs the caller can `get` |
| `GET …/namespaces/{ns}/wafs/{name}/traces` | `waf.eval` list (full profile) — [Capture](capture/) |
| `GET …/namespaces/{ns}/wafs/{name}/directives` | Assembled SecLang (`Accept: text/plain` for download) |

## Headlamp Observe

With the kubeWAF Headlamp plugin: sidebar **kubeWAF → Observe** is a service
map, flow table, eval log stream, and catalog tiles. Data is SAR-scoped
`clustermetrics` plus per-WAF `…/traces`. WAF detail shows health, request
list, and `waf.eval` timeline. See [Capture](capture/#headlamp).

## Operator metrics

The operator exposes inventory gauges (separate from the Envoy catalog):

| Metric | Labels |
|--------|--------|
| `kubewaf_waf_total` | `namespace` |
| `kubewaf_waf_ready` | `namespace`, `name` |
| `kubewaf_waf_crs_enabled` | `namespace`, `name` |
| `kubewaf_rules_loaded` | `namespace`, `name`, `policy_type` |
| `kubewaf_ruleset_total` / `kubewaf_secrule_total` | `namespace` |

`monitoring.enabled` installs a ServiceMonitor for the operator. Managed
PrometheusRules (`observability.managed.alerts`, default on when the CRD
exists) alert on catalog block rate and `kubewaf_waf_ready`. Optional DIY
groups: `monitoring.rules.wafAlerts`.

## DIY scrape (Envoy `/stats`)

This is **not** the managed product API. Prefer the Helm plane above.

Envoy Gateway: attach an `EnvoyProxy` with `spec.telemetry.metrics.prometheus: {}`,
port-forward admin `:19000`, and grep `kubewaf_waf` / `modsecurity_proxy_wasm`.
A ServiceMonitor sample lives in `config/samples/monitoring-waf-metrics.yaml`.

Optional Grafana JSON (DIY scrape / older panels):
`/grafana-kubewaf-dashboard.json` and `/grafana-kubewaf-alert-rules.json`.

`proxy_log` structured JSON (`rule_match`, `tx_interrupt`) stays on the filter
for local debug and go-ftw. There is no managed log store.

See [WAF CRD](/docs/reference/crds/waf/) for `metrics` and `telemetry`.
