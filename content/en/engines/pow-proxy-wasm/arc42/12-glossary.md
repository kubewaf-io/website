---
title: "12. Glossary"
linkTitle: "12. Glossary"
description: "arc42 §12 — terms used in pow-proxy-wasm architecture"
weight: 12
content_type: concept
---

| Term | Definition |
|------|------------|
| **ActionContinue** | Proxy-WASM result: let Envoy continue the filter chain for this request |
| **ActionPause** | Used with a local response so the filter owns the HTTP reply |
| **arc42** | Template for architecture documentation (this section tree) |
| **base64url** | URL-safe Base64 encoding; Raw form omits `=` padding |
| **Building block** | Static unit of structure (module, component) |
| **challenge cookie** | Base64url JSON challenge payload |
| **challenge-sig** | Base64url HMAC of the challenge string |
| **challenge-nonce** | PoW solution nonce set by the browser |
| **challenge-clearance** | Long-lived access cookie after successful PoW |
| **challenge-token** | Optional JSON header carrying `{c,s,n}` for non-browser clients |
| **Clearance** | Signed access credential after solve; IP-bound; ~30 min |
| **connection.id** | Envoy downstream connection identifier exposed to Wasm |
| **Difficulty** | Required leading zero **bits** in SHA-256(PoW input) |
| **Envoy** | L7 proxy hosting the Wasm filter |
| **Fail closed** | Refuse to run (e.g. missing secret at start) |
| **Fail open** | Allow traffic on certain internal failures (challenge generate) |
| **HMAC** | Hash-based Message Authentication Code — keyed integrity tag |
| **Hot path** | Common request path with valid clearance |
| **HttpOnly** | Cookie flag: not readable from JavaScript |
| **Leading zero bits** | PoW target: first N bits of the digest must be zero |
| **PoW** | Proof of Work |
| **pow-proxy-wasm** | This project / product name and Wasm/OCI artifact base name |
| **Proxy-WASM** | ABI for Wasm plugins in Envoy and similar hosts |
| **Reactor module** | Wasm module initialized via `_initialize` (c-shared build) |
| **Secret** | Shared HMAC key for the filter fleet (≥ 32 bytes) |
| **SameSite=Lax** | Cookie attribute limiting cross-site send behaviour |
| **SHA-256** | 256-bit cryptographic hash function |
| **Stateless** | No server-side session store; verification uses crypto only |
| **V8** | Wasm runtime used by Envoy for this plugin |
| **wasip1** | Go `GOOS` target for WebAssembly + WASI |
| **Wasm** | WebAssembly |

## Related reading

- [How it works](../../how-it-works/)  
- [Configuration](../../configuration/)  
- [GitHub repository](https://github.com/kubewaf-io/pow-proxy-wasm)  
