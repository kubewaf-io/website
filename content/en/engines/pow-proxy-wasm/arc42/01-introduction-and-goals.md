---
title: "1. Introduction and goals"
linkTitle: "1. Introduction and goals"
description: "arc42 §1 — requirements, stakeholders, quality goals for pow-proxy-wasm"
weight: 1
content_type: concept
---

## 1.1 Requirements overview

**pow-proxy-wasm** is an HTTP filter for **Envoy** (Proxy-WASM / V8) that forces
unknown clients to complete a **browser Proof-of-Work (PoW)** before traffic is
forwarded to the next filter or upstream.

### Functional requirements

| ID | Requirement |
|----|-------------|
| FR-1 | Issue a signed challenge (HMAC) and self-contained HTML solver when no valid proof is present |
| FR-2 | Accept a valid PoW solution (cookies or `challenge-token` header) without a separate POST verify API |
| FR-3 | After PoW success, issue a longer-lived **clearance** cookie and drop one-shot solve cookies |
| FR-4 | On subsequent requests, accept valid clearance and continue the filter chain |
| FR-5 | Bind challenge/PoW to client IP and (when available) Envoy `connection.id`; bind clearance to IP only |
| FR-6 | Support static difficulty bounds and optional adaptive difficulty under load |
| FR-7 | Support optional response header injection after successful pass-through |
| FR-8 | Refuse to start without a sufficiently long HMAC secret (no hardcoded default) |

### Explicit non-goals

| ID | Non-goal |
|----|----------|
| NG-1 | Full bot-management / ML / device fingerprinting platform |
| NG-2 | Human CAPTCHA (image/audio recognition) |
| NG-3 | Replacement for authentication, authorization, or mTLS |
| NG-4 | Cluster-wide shared anti-replay store (design is intentionally stateless) |

## 1.2 Quality goals

| Priority | Quality goal | Motivation |
|----------|--------------|------------|
| 1 | **Stateless scale-out** | Any replica can verify tokens with the same secret |
| 2 | **Low cost on happy path** | Valid clearance should add only modest latency vs bare Envoy |
| 3 | **Operational simplicity** | Single Wasm artifact, JSON config, no DB |
| 4 | **Security of token minting** | Unforgeable challenges/clearance without the secret |
| 5 | **Self-contained client** | No CDN/fonts/external JS on the challenge page |
| 6 | **Observability-friendly** | Structured logs; optional response header marker |

## 1.3 Stakeholders

| Stakeholder | Interest |
|-------------|----------|
| Platform / SRE | Deploy on Envoy/Istio/kubeWAF; tune difficulty; rotate secret |
| Security engineering | Threat model, binding, fail-open behaviour |
| Application owners | Reduce scraper noise without app code changes |
| kubeWAF operator | Map `spec.challenge` → plugin config |
| Contributors | Clear architecture for extending crypto/UI/difficulty |

## 1.4 System name and status

- **Name:** pow-proxy-wasm  
- **Module:** `github.com/kubewaf-io/pow-proxy-wasm`  
- **Status:** **Alpha** — config and token formats may still evolve  
