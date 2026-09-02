---
title: "3. Context and scope"
linkTitle: "3. Context and scope"
description: "arc42 §3 — business and technical context for pow-proxy-wasm"
weight: 3
content_type: concept
---

## 3.1 Business context

```mermaid
flowchart LR
  User[Browser / API client]
  Edge[Edge / mesh Envoy]
  POW[pow-proxy-wasm]
  App[Application / API]
  Ops[Operators]

  User -->|HTTP| Edge
  Edge --> POW
  POW -->|allowed| App
  POW -->|403 + challenge HTML| User
  Ops -->|plugin JSON / secret / difficulty| POW
```

| Neighbour | Interface | Direction |
|-----------|-----------|-----------|
| Browser | Cookies + HTML page | Bidirectional |
| Non-browser client | `challenge-token` header | Client → filter |
| Envoy host | Proxy-WASM ABI (headers, properties, local response, tick) | Bidirectional |
| Upstream / next filter | Continues only if filter returns continue | Filter → host |
| Operator / kubeWAF | Configuration JSON (secret, difficulty, …) | Config → plugin |

### Business value

Raise the cost of automated scraping and cheap bots at L7 **without** application changes and **without** centralized session state.

## 3.2 Technical context

```mermaid
flowchart TB
  subgraph host [Envoy process]
    HCM[HTTP connection manager]
    WF[Wasm filter runtime V8]
    RT[Router / other filters]
    HCM --> WF
    WF --> RT
  end
  subgraph guest [pow-proxy-wasm Wasm module]
    PC[pluginContext]
    HC[httpHeaders]
    CR[crypt.go logic]
    HTML[embedded challenge.html]
    PC --> HC
    HC --> CR
    HC --> HTML
  end
  WF --- guest
```

### External technical interfaces

| Interface | Technology | Notes |
|-----------|------------|-------|
| Plugin config | JSON string in Envoy Wasm `configuration` | Parsed at `OnPluginStart` |
| Request headers / cookies | HTTP | Cookie parse; optional `challenge-token`, `x-challenge-difficulty` |
| Response | Local 403 + body **or** pass-through | `SendHttpResponse` vs `ActionContinue` |
| Downstream identity | Envoy properties + optional XFF / X-Real-IP | See binding rules |
| Shared data | Proxy-WASM shared KV | Dynamic difficulty publish only |

## 3.3 Scope boundaries

**In scope:** challenge issue, PoW verify, clearance mint/verify, optional header inject, adaptive difficulty heuristics, standalone Envoy example, CI/tests.

**Out of scope:** secret distribution (K8s secrets / operator), TLS termination policy, rate-limit algorithms, WAF rules (see modsecurity-proxy-wasm), UI branding beyond the embedded page.
