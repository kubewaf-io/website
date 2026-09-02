---
title: "4. Solution strategy"
linkTitle: "4. Solution strategy"
description: "arc42 §4 — fundamental solution approaches for pow-proxy-wasm"
weight: 4
content_type: concept
---

## 4.1 Technology choices

| Choice | Rationale |
|--------|-----------|
| **Proxy-WASM + Envoy** | Runs in the data plane next to other L7 filters; portable across Envoy-based meshes |
| **Go + proxy-wasm-go-sdk** | Productive language; matches team skills; wasip1 builds for V8 |
| **HMAC-SHA256 tokens** | Stateless authenticity; shared secret only; no encryption needed for public payload fields |
| **Embedded HTML solver** | Zero external dependencies; works offline; consistent versioning with the Wasm binary |
| **Cookie-based solve** | No custom POST API; browser sets cookies and reloads |

## 4.2 Top-level decomposition

| Layer | Responsibility | Primary code |
|-------|----------------|--------------|
| Crypto / tokens | Challenge, PoW verify, clearance | `crypt.go` |
| Host glue | Config, headers, cookies, IP, tick | `main.go` |
| Client | SHA-256 search UI | `challenge.html` |

## 4.3 Key approaches mapped to quality goals

| Quality goal | Strategy |
|--------------|----------|
| Stateless scale-out | All authority in HMAC; no shared session DB |
| Cheap happy path | Clearance-first path; fixed-layout clearance; reuse HMAC digester; one-pass cookie parse; optional peer-only IP |
| Simplicity | One plugin config JSON; single Wasm artifact |
| Token security | Secret ≥ 32 bytes mandatory; constant-time compare; short challenge TTL |
| Self-contained client | `//go:embed challenge.html` |
| Load shedding | Local counters + periodic tick bump difficulty under challenge pressure |

## 4.4 Credential model (two phases)

1. **Solve phase (≤ 60s):** signed challenge + nonce. Bound tightly (IP + connection.id when available).  
2. **Access phase (≤ 30 min):** clearance cookie. Bound loosely (IP only) so navigation works.

Replaying raw PoW for half an hour would make the solution a long-lived bearer; clearance separates those roles.

## 4.5 Fail-open vs fail-closed

| Situation | Behaviour |
|-----------|-----------|
| Missing / short secret at start | **Fail closed** — plugin does not start |
| Invalid / expired token | **Re-challenge** (403) |
| Challenge generation error (RNG/crypto) | **Fail open** — continue without challenge (availability preference) |

This trade-off is intentional for alpha edge use; document it in ops runbooks.
