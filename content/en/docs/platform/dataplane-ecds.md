---

title: "Data plane (ECDS)"
description: "How kubeWAF pushes config over ECDS to Envoy-based gateways"
weight: 30
content_type: task
aliases:
  - "/docs/tasks/dataplane-ecds/"
  - "/docs/operator/dataplane-ecds/"
  - "/docs/kubewaf/operator/dataplane-ecds/"
---
This guide is the **authoritative description** of how kubeWAF pushes config into
Envoy and how Envoy Gateway, Istio, and Cilium attach the filter.

## Overview

```mermaid
flowchart TB
  subgraph k8s["Kubernetes"]
    WAF[WAF CR<br/>engine + optional challenge]
    RS[RuleSets / SecRules]
  end

  subgraph op["kubeWAF operator"]
    BUILD[Build portable config<br/>ordered Filters]
    ECDS[ECDS :18001]
    WASM[Multi-module Wasm HTTP :18002]
    SLOT[Slot installer]
  end

  subgraph dp["Envoy"]
    STUB1[challenge stub]
    STUB2[WAF stub]
    CH[pow-proxy-wasm]
    MOD[modsecurity-proxy-wasm]
  end

  RS --> BUILD
  WAF --> BUILD
  BUILD --> ECDS
  BUILD --> SLOT
  SLOT --> STUB1
  SLOT --> STUB2
  STUB1 -->|gRPC| ECDS
  STUB2 -->|gRPC| ECDS
  CH -->|GET challenge wasm| WASM
  MOD -->|GET engine wasm| WASM
  ECDS --> CH
  ECDS --> MOD
```

**Key idea:** rule updates are pure ECDS publishes. Platform-specific resources
only install **stubs**. Engines and challenge modules are separate wasm binaries
served by the operator (see [WAF engine](/docs/platform/engine/) and [challenge](/docs/users/challenge/)).

Unresolved RuleSet or SecLang refs skip the new ECDS upsert. The last good
snapshot stays on Envoy. Missing custom PhraseList/IPList files follow
`spec.phraseListPolicy` (`FailClosed` by default).

## Architecture deep dive

### What Envoy sees

```mermaid
flowchart TB
  subgraph hcm["HttpConnectionManager.http_filters"]
    F0[other filters…]
    F1["name: kubewaf/shop/shop-waf/challenge<br/>config_discovery"]
    F2["name: kubewaf/shop/shop-waf<br/>config_discovery"]
    F3[envoy.filters.http.router]
  end

  subgraph clusters["Clusters"]
    C1["kubewaf_ecds → operator:18001 HTTP/2"]
    C2["kubewaf_wasm_code → operator:18002 HTTP/1"]
  end

  F1 --> C1
  F2 --> C1
  C2 --> CH[challenge wasm]
  C2 --> WAF[modsecurity-proxy-wasm]
```

### ECDS resource naming

| Item | Value |
|------|--------|
| WAF filter name | `kubewaf/<namespace>/<waf-name>` |
| Challenge filter name | `kubewaf/<namespace>/<waf-name>/challenge` |
| Example | `kubewaf/shop/shop-waf` |
| Cluster for ECDS | `kubewaf_ecds` |
| Cluster for wasm fetch | `kubewaf_wasm_code` (Cilium ECDS RemoteDataSource uses the CEC-prefixed name `<ns>/kubewaf-<waf>/kubewaf_wasm_code`) |

### Rule update vs slot update

```mermaid
sequenceDiagram
  participant U as User
  participant API as K8s API
  participant L as Leader
  participant P as All pods
  participant E as Envoy

  U->>API: update SecRule
  API->>L: reconcile WAF
  API->>P: dataplane sync
  L->>P: ECDS Upsert vN+1
  P->>P: new snapshot
  E->>P: ECDS stream
  P-->>E: new TypedExtensionConfig
  Note over E: Filter slot unchanged
```

## Wasm binary delivery (multi-module)

Envoy must **HTTP-fetch** each `.wasm` (OCI alone is not used on pure ECDS).

```mermaid
flowchart LR
  subgraph monorepo["engines/ submodules · image /wasm · optional volume"]
    M[modsecurity-proxy-wasm]
    P[pow-proxy-wasm]
  end

  subgraph serve["Operator HTTP :18002"]
    H2["/wasm/modsecurity-proxy-wasm.wasm"]
    H3["/wasm/challenge-proxy-wasm.wasm"]
  end

  M --> H2
  P --> H3
  serve --> E[Envoy remote code]
```

### Operator hosts modules

Wasm binaries live on the operator at:

| Module | Path |
|--------|------|
| ModSecurity | `/wasm/modsecurity-proxy-wasm.wasm` |
| Challenge | `/wasm/challenge-proxy-wasm.wasm` |

Ko images also resolve them under `KO_DATA_PATH/wasm`. From an operator checkout (`engines/` submodules):

```bash
make wasm-build   # → dist/wasm/*.wasm
```

Default Envoy URLs (operator Service):

```text
http://<release>-ecds.<ns>.svc:18002/wasm/modsecurity-proxy-wasm.wasm
http://<release>-ecds.<ns>.svc:18002/wasm/challenge-proxy-wasm.wasm
```

Operator guides: [WAF engine](/docs/platform/engine/) · [challenge](/docs/users/challenge/).

## Provider: Envoy Gateway

```mermaid
sequenceDiagram
  participant EG as Envoy Gateway
  participant XS as kubeWAF Extension Server :5005
  participant EN as Envoy
  participant EC as kubeWAF ECDS :18001

  EG->>XS: PostHTTPListenerModify(listener, WAF policies)
  XS-->>EG: listener + config_discovery filter
  EG->>XS: PostTranslateModify(clusters…)
  XS-->>EG: clusters + kubewaf_ecds (+ wasm cluster)
  EG->>EN: xDS (ADS)
  EN->>EC: ECDS stream
  EC-->>EN: Wasm TypedExtensionConfig
```

### Enable Extension Server on Envoy Gateway

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyGateway
provider:
  type: Kubernetes
gateway:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
extensionManager:
  policyResources:
    - group: waf.kubewaf.io
      version: v1beta1
      kind: WAF
  hooks:
    xdsTranslator:
      post:
        - HTTPListener
        - Translation
  service:
    fqdn:
      hostname: kubewaf-ecds.kubewaf-system.svc.cluster.local
      port: 5005
```

Restart Envoy Gateway after changing this config.

### Example WAF

```yaml
apiVersion: waf.kubewaf.io/v1beta1
kind: WAF
metadata:
  name: shop-waf
  namespace: shop
spec:
  provider:
    type: EnvoyGateway
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: external
  crsEnable: false
  ruleRefs:
    - kind: RuleSet
      name: shop-rules
```

Full guide: [Envoy Gateway Integration](/docs/platform/providers/envoy-gateway/).

## Provider: Istio

```mermaid
flowchart TB
  WAF[WAF provider=Istio] --> EF[EnvoyFilter kubewaf-*]
  EF --> C1[ADD cluster kubewaf_ecds]
  EF --> C2[ADD cluster kubewaf_wasm_code]
  EF --> F[INSERT_BEFORE router<br/>config_discovery]
  F --> ECDS[kubeWAF ECDS]
  ECDS --> W[Wasm + directives]
```

No Istio control-plane flag is required. kubeWAF creates the `EnvoyFilter`.

```yaml
spec:
  provider:
    type: Istio
    istio:
      workloadSelector:
        istio: ingressgateway
      context: GATEWAY
```

Full guide: [Istio Integration](/docs/platform/providers/istio/).

## Provider: Cilium

```mermaid
flowchart TB
  WAF[WAF provider=Cilium] --> CEC[CiliumEnvoyConfig]
  CEC --> S[services: target Service]
  CEC --> R[resources: kubewaf_wasm_code + Listener]
  R --> F[config_discovery]
  BOOT[cilium-envoy bootstrap STATIC kubewaf_ecds] --> ECDS[kubeWAF ECDS]
  F --> BOOT
```

```yaml
spec:
  provider:
    type: Cilium
    cilium:
      serviceName: shop-frontend
      serviceNamespace: shop
```

{{% alert title="Cilium bootstrap" color="warning" %}}
`kubewaf_ecds` must be a **STATIC** cluster on the `cilium-envoy` bootstrap
(ClusterIP `:18001`). CEC `config_discovery` is the same stub as EG/Istio.
See [Cilium Integration](/docs/platform/providers/cilium/).
{{% /alert %}}



## Multi-replica / HA

```mermaid
flowchart TB
  subgraph pods["Deployment replicas ≥ 2"]
    P1[Pod A leader]
    P2[Pod B]
    P3[Pod C]
  end

  SVC[Service kubewaf-ecds]

  P1 --- SVC
  P2 --- SVC
  P3 --- SVC

  EN1[Envoy] --> SVC
  EN2[Envoy] --> SVC
  EG[Envoy Gateway] --> SVC

  P1 -->|writes status EnvoyFilter CEC| API[(API server)]
  P1 & P2 & P3 -->|serve ECDS wasm EG hooks| EN1
```

| Component | Runs on | Leader election |
|-----------|---------|-----------------|
| ECDS gRPC | every pod | no |
| Wasm HTTP | every pod | no |
| EG Extension Server | every pod | no |
| Dataplane sync controller | every pod | no |
| WAF controller (status, slots, finalizers) | leader | yes |
| Inventory metrics | leader | yes |

Helm defaults:

```yaml
replicaCount: 2
leaderElection:
  enabled: true
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

## Status fields

```bash
kubectl get waf shop-waf -o yaml
```

| Field | Meaning |
|-------|---------|
| `status.provider` | Resolved provider |
| `status.engine` | WAF engine (e.g. `ModSecurity`) |
| `status.challengeEnabled` | PoW filter installed |
| `status.ecdsResourceName` | Primary WAF ECDS name |
| `status.ecdsVersion` | Snapshot counter |
| `status.slotKind` | `ExtensionServer` / `EnvoyFilter` / `CiliumEnvoyConfig` |
| `status.slotName` | Platform object name (if any) |
| `status.conditions[Ready]` | Overall health |

## Operator flags (summary)

| Flag | Default | Purpose |
|------|---------|---------|
| `--leader-elect` | `true` | Multi-replica safety for writes |
| `--ecds-bind-address` | `:18001` | ECDS listen |
| `--extension-server-bind-address` | `:5005` | EG hooks |
| `--wasm-serve-bind-address` | `:18002` | Multi-module wasm HTTP |
| `--ecds-service-host` | chart FQDN | DNS name for Envoy clusters |

## E2E

Provider tests live under `test/e2e/`. See [test/e2e/README.md](https://github.com/kubewaf-io/kubewaf/blob/main/test/e2e/README.md).

```bash
make test-e2e-envoy-gateway
make test-e2e-istio
make test-e2e-cilium
```

## Related guides

- [WAF engine](/docs/platform/engine/)
- [Proof-of-Work challenge](/docs/users/challenge/)
- [Challenge Proxy-WASM (PoW)](/engines/pow-proxy-wasm/)
- [Architecture](/docs/get-started/architecture/)
- [Envoy Gateway](/docs/platform/providers/envoy-gateway/)
- [Istio](/docs/platform/providers/istio/)
- [Cilium](/docs/platform/providers/cilium/)
- [Observability](/docs/platform/observability/)
