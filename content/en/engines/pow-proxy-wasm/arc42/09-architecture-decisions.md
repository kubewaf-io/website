---
title: "9. Architecture decisions"
linkTitle: "9. Architecture decisions"
description: "arc42 §9 — important architecture decisions (ADR-style) for pow-proxy-wasm"
weight: 9
content_type: concept
---

## ADR-1: Stateless HMAC tokens instead of server sessions

| | |
|--|--|
| **Status** | Accepted |
| **Context** | Need multi-replica Envoy without shared session store |
| **Decision** | Sign challenges and clearance with shared HMAC secret |
| **Consequences** | Easy HA; secret rotation is a fleet operation; no server-side revoke list |

## ADR-2: Two credentials (challenge vs clearance)

| | |
|--|--|
| **Status** | Accepted |
| **Context** | PoW solution could become a long-lived bearer if replayed for 30 min |
| **Decision** | 60 s solve cookies; after success mint HttpOnly clearance and delete solve cookies |
| **Consequences** | Slightly more code; clearer security story |

## ADR-3: Cookie solve without POST verify API

| | |
|--|--|
| **Status** | Accepted |
| **Context** | Prefer simple browser flow and fewer endpoints |
| **Decision** | Browser sets cookies and reloads; filter verifies on next request |
| **Consequences** | Relies on cookies; `fetch`+reload used to keep connection.id when possible |

## ADR-4: Fixed-layout clearance (not JSON)

| | |
|--|--|
| **Status** | Accepted (hot-path optimization) |
| **Context** | Clearance verify is the common path after first solve |
| **Decision** | Pack `exp‖salt‖ip` binary + base64url + HMAC; no `encoding/json` on verify |
| **Consequences** | Faster/fewer allocs; format is a breaking change vs any older JSON clearance |

## ADR-5: Go wasip1 + c-shared reactor

| | |
|--|--|
| **Status** | Accepted |
| **Context** | Target Envoy V8 Proxy-WASM |
| **Decision** | Build with `GOOS=wasip1 GOARCH=wasm -buildmode=c-shared`; pin Go **1.24** |
| **Consequences** | Larger binary than TinyGo; Go 1.25+ of this module not Envoy-safe today |

## ADR-6: Fail-open on challenge generation failure

| | |
|--|--|
| **Status** | Accepted for alpha |
| **Context** | RNG/crypto failure is rare; hard-down may be worse for availability |
| **Decision** | Log error and `ActionContinue` without issuing challenge |
| **Consequences** | Attackers benefit if generation is broken; monitor logs |

## ADR-7: Adaptive difficulty via local counters

| | |
|--|--|
| **Status** | Accepted (heuristic) |
| **Context** | Under attack, static difficulty may be too low |
| **Decision** | Count local challenge issues; every 5 s bump difficulty up to max |
| **Consequences** | Not cluster-global; heuristics need ops tuning |

## ADR-8: Product naming pow-proxy-wasm

| | |
|--|--|
| **Status** | Accepted |
| **Context** | Align module, image, artifact, and docs under one name |
| **Decision** | Use **pow-proxy-wasm** everywhere for packaging; keep `challenge*` cookie protocol names |
| **Consequences** | Protocol cookies remain stable; packaging renames must stay consistent |
