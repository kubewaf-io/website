---
title: Security policy
linkTitle: Security
weight: 20
description: >
  How to report vulnerabilities in kubeWAF, engines, and this documentation site.
content_type: concept
aliases:
  - "/security/"
---

We take security reports seriously. Please **do not** open public GitHub issues for
vulnerabilities that could be exploited in production clusters.

## Scope

In scope:

- kubeWAF operator (controllers, CRDs, Helm chart, ECDS / wasm serve)
- In-tree or submodule engines: **modsecurity-proxy-wasm**, **pow-proxy-wasm**
- Sample configs that ship unsafe defaults (if present)

Out of scope (report upstream when possible):

- Envoy, Envoy Gateway, Istio, Cilium themselves
- Upstream OWASP CRS rule false positives (tune via kubeWAF CRS fields)
- Compromised third-party container images used as operator Wasm sources

## How to report

1. Email **[hello@kubewaf.io](mailto:hello@kubewaf.io)** with subject  
   `SECURITY: <short title>`.
2. Or use GitHub **private vulnerability reporting** on  
   [kubewaf-io/kubewaf](https://github.com/kubewaf-io/kubewaf/security/advisories/new)  
   if enabled for the repository.

Include when possible:

- Affected version (chart / image tag / commit)
- Component (operator, engine, chart)
- Reproduction steps and impact
- Whether a fix or workaround is already known

## What to expect

| Step | Target |
|------|--------|
| Acknowledgement | Within a few business days |
| Initial assessment | Severity + affected surfaces |
| Fix / mitigation | Coordinated with reporter when practical |
| Public disclosure | After a fix or agreed timeline |

We follow coordinated disclosure. Please give us reasonable time before public write-ups.

## Hardening checklist (operators)

- Run the operator with **leader election** and ≥2 replicas in production-like envs
- Prefer **DetectionOnly** until rules are tuned ([Beta status](/docs/get-started/beta/))
- Pin Wasm **SHA-256** via operator module sources (not per-WAF fields)
- Restrict who can create `WAF` / `RuleSet` / `SecRule` (RBAC)
- Use `RuleSet.spec.allowedRules` for cross-namespace rule contribution
- Do not enable pprof (`--enable-pprof`) on shared clusters
- Keep metrics endpoints authenticated (chart defaults lean secure)

## Related

- [Contributing](/docs/contribute/contributing/)
- [Code of conduct](/docs/contribute/code-of-conduct/)
- [Beta status](/docs/get-started/beta/)
