---
title: "8. Cross-cutting concepts"
linkTitle: "8. Cross-cutting concepts"
description: "arc42 §8 — domain, security, crypto, and patterns used throughout"
weight: 8
content_type: concept
---

## 8.1 Domain model

| Concept | Definition |
|---------|------------|
| **Challenge** | Short-lived signed puzzle describing difficulty, expiry, and binding |
| **Solution / PoW** | Nonce such that SHA-256(payload ‖ nonce) has N leading zero bits |
| **Clearance** | Longer-lived signed access credential after a successful solve |
| **Difficulty** | Number of leading zero **bits** in the SHA-256 digest |
| **Secret** | Shared HMAC key for the entire proxy fleet |

## 8.2 Cryptography (concepts used in code)

### HMAC (Hash-based Message Authentication Code)

HMAC combines a **secret key** and a **message** to produce a tag. Anyone with the
secret can verify that the message was not forged. pow-proxy-wasm uses
**HMAC-SHA256** for challenge signatures and clearance tokens.

Why not encrypt? Payload fields (expiry, IP, difficulty) are not confidential to
the client; we need **unforgeability**, not secrecy.

### SHA-256 and PoW

PoW asks the client to find a nonce where the hash has enough leading zero bits.
Verification is one hash + bit test — cheap for Envoy, expensive enough for bulk bots.

### Constant-time compare

Signatures are compared with `crypto/subtle.ConstantTimeCompare` to avoid
timing leaks on the HMAC tag.

### Base64url

Binary structures are encoded with **base64url without padding** so they fit in
cookies. The alphabet contains no `.`, so `body.sig` splits cleanly.

## 8.3 Security concepts

| Concept | Application |
|---------|-------------|
| Mandatory secret | Plugin fails to start if secret missing/short |
| Short challenge TTL | 60 s solve window |
| Separate clearance | Avoid long-lived PoW replay |
| IP binding | Reduces cross-client cookie reuse |
| connection.id binding | Tightens PoW to one downstream connection when available |
| SameSite=Lax | Default CSRF-oriented cookie attribute |
| HttpOnly clearance | JS cannot read long-lived access cookie |

## 8.4 Identity resolution

Order for client IP (`client_ip_source: auto`):

1. Envoy `source.address`  
2. Left-most `X-Forwarded-For`  
3. `X-Real-IP`  
4. Empty (skip IP binding)

`source_address` mode uses only (1) — fewer hostcalls at a true edge.

## 8.5 Performance patterns

- Clearance-first path (skip connection.id on happy path)  
- Reusable HMAC digester per plugin context  
- One-pass cookie scan  
- Local counters for difficulty (host shared data only on tick)  
- Lazy HTTPS detection (only when setting cookies)

## 8.6 User experience

- Single embedded page, system dark/light theme  
- Sync JS SHA-256 for higher hash rate  
- Progress UI (difficulty, rate, time, tries)  
- `fetch` before reload to preserve connection for PoW verify when possible  

## 8.7 Development patterns

- Pure crypto in `crypt.go` unit-tested without Envoy  
- Integration tests with real Envoy + bats  
- k6: baseline vs valid-token comparison  
- Renovate for Go modules, Actions, Envoy, k6, bats  
