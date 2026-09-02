---
title: "5. Building block view"
linkTitle: "5. Building block view"
description: "arc42 §5 — static structure of pow-proxy-wasm"
weight: 5
content_type: concept
---

## 5.1 Whitebox overall system

```mermaid
flowchart TB
  subgraph POW [pow-proxy-wasm]
    subgraph main [main.go]
      VM[vmContext]
      PL[pluginContext]
      HT[httpHeaders]
      CK[Cookie helpers]
      IP[IP / connection.id]
      DY[Dynamic difficulty]
      VM --> PL
      PL --> HT
      HT --> CK
      HT --> IP
      PL --> DY
    end
    subgraph crypt [crypt.go]
      CH[Challenge generate/verify]
      CL[Clearance generate/verify]
      POW_CHK[PoW leading-zero check]
    end
    HTML[challenge.html embed]
    HT --> CH
    HT --> CL
    CH --> POW_CHK
    HT --> HTML
  end
  Envoy[Envoy Wasm host]
  Envoy <--> HT
  Envoy <--> PL
```

## 5.2 Level 1 building blocks

| Block | Responsibility | Interfaces |
|-------|----------------|------------|
| **vmContext** | Register plugin factory | Proxy-WASM VM API |
| **pluginContext** | Config, secret, HMAC instance, difficulty state, tick | `OnPluginStart`, `OnTick`, `NewHttpContext` |
| **httpHeaders** | Per-request decision tree | `OnHttpRequestHeaders`, `OnHttpResponseHeaders` |
| **crypt package functions** | Portable crypto | Pure Go functions (also unit-tested) |
| **challenge.html** | Browser PoW UI | Cookies + navigation |

## 5.3 Important files (repository)

| Path | Role |
|------|------|
| `main.go` | Filter lifecycle, cookies, IP, difficulty |
| `crypt.go` | HMAC challenge/clearance, PoW verify |
| `challenge.html` | Client solver |
| `test/tools/powcli` | Offline mint/solve helper |
| `example/envoy` | Manual docker-compose demo |
| `test/fixtures`, `test/integration`, `test/perf` | Automated quality gates |

## 5.4 Blackbox crypt API (conceptual)

| Operation | Input | Output |
|-----------|-------|--------|
| Generate challenge | secret, difficulty, client context | `{c, s}` base64url pair |
| Verify solution | secret, `{c,s,n}`, expected context | ok / typed error |
| Generate clearance | secret, IP | `body.sig` cookie value |
| Verify clearance | secret, token, expected IP | ok / typed error |

## 5.5 Plugin configuration schema (blackbox)

See also [Configuration](../../configuration/).

| Field | Type | Required |
|-------|------|----------|
| `secret` | string ≥ 32 | yes |
| `base_difficulty` | uint | no (18) |
| `min_difficulty` | uint | no (12) |
| `max_difficulty` | uint | no (26) |
| `header` / `value` | string | no |
| `client_ip_source` | `auto` \| `source_address` | no (`auto`) |
