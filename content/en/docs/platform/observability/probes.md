---
title: Rule probes
linkTitle: Probes
weight: 30
description: >
  Dry-run an HTTP request against a SecRule, RuleSet, or WAF via the
  subresources.kubewaf.io API.
content_type: task
aliases:
  - /docs/platform/probes/
---

Probes send a simulated HTTP request through **go-coraza** and return which
rules would fire. The dataplane still uses **ModSecurity**. Treat probe results
as authoring help, not a guarantee of production parity (`EngineParity=False`).

The API is **off** by default (`subresourceApi.enabled`). It lives on the
aggregated `subresources.kubewaf.io` group next to
[metrics / traces](/docs/platform/observability/) and
[capture](/docs/platform/observability/capture/).

## Enable

```bash
helm upgrade kubewaf oci://ghcr.io/kubewaf-io/charts/kubewaf \
  --namespace kubewaf-system \
  --version v0.1.0-beta.1 \
  --reuse-values \
  --set subresourceApi.enabled=true \
  --set probeTestServer.enabled=true
```

Enable both `subresourceApi.enabled` and `probeTestServer.enabled`.
`probes.enabled` defaults true; the chart **fails** if the Test Server is off.
For query or directives only, set `subresourceApi.probes.enabled=false`.

Optional siblings (no Test Server): `subresourceApi.directives` (`GET …/wafs/{name}/directives`)
and `subresourceApi.query` (`…/metrics`, `…/traces`, `…/clustermetrics`).

## Call

No request body schema. The client HTTP request **is** the simulated traffic.

```bash
kubectl proxy --port=8001 &

curl -sS -X GET \
  'http://127.0.0.1:8001/apis/subresources.kubewaf.io/v1alpha1/namespaces/demo/secrules/block-bad-user-agent/probes/http/search' \
  -H 'User-Agent: sqlmap/1.0'
```

Parents: `secrules`, `rulesets`, `wafs`. Path `/probes` is `/`; `/probes/http/{path}` is the app path.

| Header | Role |
|--------|------|
| `X-KubeWAF-Probe-Mode` | Echo only (`DetectionOnly` / `Blocking`). Eval is always `SecRuleEngine On`. |
| `X-KubeWAF-Probe-TimeoutSeconds` | Deadline |
| `X-KubeWAF-Probe-Max-Matches` | Cap match list |
| `X-KubeWAF-Probe-Remote-Addr` | Simulated client IP |
| `X-KubeWAF-Probe-CrsEnable` | Path A — **422** (`CorazaCRSPathAUnsupported`) |

Auth: RBAC on `secrules/probes` (and siblings) plus SAR `get` on the parent CR.
Bind ClusterRole `<release>-probe`. Hop-by-hop, `Authorization`, `Cookie`,
and `X-Remote-*` headers are stripped.

HTTP **200** + JSON (`status.matches`, `status.interruption`,
`status.http.wouldStatus`, …).
Errors are `metav1.Status`. Body max **1 MiB** (413).

Unresolved RuleSet members or assigned IDs → **422**. Missing custom data files
follow FailClosed (WAF honors `spec.phraseListPolicy`).

## Related

- [Writing security rules](/docs/security/writing-rules/)
- [Observability](/docs/platform/observability/)
- [Capture](/docs/platform/observability/capture/)
- [Installation](/docs/platform/installation/)
