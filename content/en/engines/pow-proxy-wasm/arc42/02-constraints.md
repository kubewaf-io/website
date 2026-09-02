---
title: "2. Constraints"
linkTitle: "2. Constraints"
description: "arc42 §2 — technical, organizational, and conventional constraints"
weight: 2
content_type: concept
---

## 2.1 Technical constraints

| Constraint | Impact on design |
|------------|------------------|
| Must run as **Proxy-WASM** guest in Envoy V8 | Limited host ABI; no arbitrary OS APIs; single-threaded guest per VM |
| **Go wasip1** toolchain | Binary size ~4 MiB; **Go 1.24.x** required — Go 1.25+ builds of this module import WASI path APIs Envoy does not provide |
| `-buildmode=c-shared` reactor | Module uses `_initialize`, not full WASI `_start` |
| No shared DB assumed | HMAC-signed tokens; no server-side session store |
| Browser must solve PoW | Challenge page needs readable cookies (`challenge` / `challenge-sig`); clearance is HttpOnly |
| Cookie size / header limits | Compact clearance (fixed binary layout); base64url encoding |

## 2.2 Organizational constraints

| Constraint | Notes |
|------------|--------|
| Open source (Apache-2.0) | Public repo under kubewaf-io |
| Documented for kubeWAF + standalone Envoy | Operator injects config; this tree documents the filter |
| Alpha release process | Pre-release tags do not promote GHCR `:latest` |

## 2.3 Conventions

| Area | Convention |
|------|------------|
| Language | Go, standard library crypto where possible |
| Config | JSON plugin configuration via Envoy Wasm filter |
| Naming | Product **pow-proxy-wasm**; cookie protocol uses `challenge*` names |
| Logging | Debug for common success/stale paths; avoid Info spam under load |
| Tests | Unit (pure Go), bats+Envoy integration, k6 perf (baseline vs clearance) |

## 2.4 External standards and references

- [Proxy-WASM ABI](https://github.com/proxy-wasm/spec)  
- [RFC 2104 HMAC](https://datatracker.ietf.org/doc/html/rfc2104)  
- [FIPS 180-4 SHA-256](https://csrc.nist.gov/publications/detail/fips/180/4/final)  
- [RFC 4648 base64url](https://datatracker.ietf.org/doc/html/rfc4648)  
- Envoy Wasm HTTP filter configuration  
