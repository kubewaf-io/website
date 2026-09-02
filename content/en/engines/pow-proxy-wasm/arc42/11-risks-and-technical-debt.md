---
title: "11. Risks and technical debt"
linkTitle: "11. Risks and technical debt"
description: "arc42 §11 — risks, technical debt, and open issues for pow-proxy-wasm"
weight: 11
content_type: concept
---

## 11.1 Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R-1 | Secret leak forges all tokens | Med | High | K8s secrets, rotation, least privilege |
| R-2 | Clearance cookie theft (same IP / no IP bind) | Med | Med | HTTPS, short TTL, optional stricter binding later |
| R-3 | Determined bots pay PoW cost | High | Med | Rate limit + WAF + raise max difficulty |
| R-4 | XFF spoofing breaks IP bind | Med | Med | Edge stripping; `source_address` mode |
| R-5 | Go upgrade pulls unsupported WASI | Med | High | Pin 1.24; CI; document |
| R-6 | Fail-open on generate masks outages | Low | High | Alert on generate errors |
| R-7 | Adaptive difficulty not cluster-global | Med | Low | Accept heuristic; tune thresholds |
| R-8 | Large Wasm binary memory cost | Med | Med | Monitor Envoy memory; future size work |

## 11.2 Technical debt

| Item | Notes |
|------|--------|
| Challenge payload still JSON | Hot path is clearance; challenge issue is rarer — optional future fixed layout |
| Difficulty heuristics are magic numbers | Need production feedback |
| No formal secret rotation protocol | Ops process outside the filter |
| No metrics export beyond logs | Could add Proxy-WASM metrics counters |
| Alpha naming cleanup in older docs | Keep engine docs aligned with `pow-proxy-wasm` artifact name |

## 11.3 Open issues / future options

- Optional VM-local clearance cache (trade memory for HMAC CPU)  
- Configurable fail-closed on generate failure  
- Cluster-coordinated difficulty via external control plane  
- Smaller guest (different toolchain) if Envoy WASI surface improves  
- Formal threat model document for enterprise reviews  

## 11.4 Known limitations (operator-facing)

Documented for alpha honesty:

- Clearance is a **bearer** cookie with optional IP binding, not one-time use.  
- No shared anti-replay store.  
- PoW is a cost barrier, not a proof of humanity.  
- Rebuild requires **Go 1.24.x** for Envoy.  
