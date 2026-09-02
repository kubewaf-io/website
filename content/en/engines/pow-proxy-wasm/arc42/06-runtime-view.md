---
title: "6. Runtime view"
linkTitle: "6. Runtime view"
description: "arc42 §6 — runtime scenarios for pow-proxy-wasm"
weight: 6
content_type: concept
---

## 6.1 Scenario: first visit (issue challenge)

```mermaid
sequenceDiagram
  participant B as Browser
  participant E as Envoy + pow-proxy-wasm
  participant U as Upstream
  B->>E: GET / (no cookies)
  Note over E: No clearance / no PoW
  E-->>B: 403 + HTML + Set-Cookie challenge, challenge-sig
  Note over B: challenge.html runs SHA-256 loop
  B-->>B: set challenge-nonce
  B->>E: fetch/reload with solve cookies
  E->>U: continue (after PoW verify)
  U-->>E: 200
  E-->>B: 200 + Set-Cookie challenge-clearance<br/>clear solve cookies
```

## 6.2 Scenario: return visit (clearance hot path)

```mermaid
sequenceDiagram
  participant B as Browser
  participant E as Envoy + pow-proxy-wasm
  participant U as Upstream
  B->>E: GET / Cookie: challenge-clearance=...
  Note over E: parse cookies → IP → HMAC verify fixed-layout token
  E->>U: ActionContinue
  U-->>B: 200 (+ optional injected header)
```

## 6.3 Decision tree (`OnHttpRequestHeaders`)

1. Parse all challenge-related cookies in one pass.  
2. **If clearance present and valid** → continue (IP only).  
3. Build full client context (IP + connection.id).  
4. **If solve cookies / token valid** → continue; mark `issueClearance`.  
5. **Else** → generate challenge, local 403 + HTML, pause.

## 6.4 Response path after PoW

When `issueClearance` is set, `OnHttpResponseHeaders`:

1. Mint fixed-layout clearance for `ClearanceBind()` (IP).  
2. Set `challenge-clearance` (HttpOnly, 30 min).  
3. Clear `challenge`, `challenge-sig`, `challenge-nonce`.  
4. Optionally inject configured response header.

## 6.5 Dynamic difficulty tick

Every **5 seconds** (`OnTick`):

1. Read and zero local `challengeCounter`.  
2. Map recent issue count → difficulty bump over base.  
3. Clamp to min/max; store `currentDiff`.  
4. Publish to shared data key `challenge:current_difficulty`.

Request path prefers local `currentDiff` to avoid shared-data hostcalls.

## 6.6 Failure scenarios

| Case | Runtime behaviour |
|------|-------------------|
| Bad / expired clearance | Fall through → may re-challenge |
| Bad PoW / signature | Fall through → re-challenge |
| Missing secret at start | Plugin start fails (Envoy config error) |
| RNG failure on generate | Fail open: continue without challenge |
