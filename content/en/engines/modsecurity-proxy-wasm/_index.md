---
title: "modsecurity-proxy-wasm"
linkTitle: "modsecurity-proxy-wasm"
description: "ModSecurity Proxy-Wasm filter with embedded OWASP CRS"
weight: 10
content_type: concept
cascade:
  type: docs
aliases:
  - "/docs/modsecurity-proxy-wasm/"
---
**modsecurity-proxy-wasm** is a [Proxy-Wasm](https://github.com/proxy-wasm/spec) HTTP
filter that runs **ModSecurity** inside Envoy (`envoy.wasm.runtime.v8`) with
**OWASP CRS** embedded in the binary.

| | |
|--|--|
| **Repository** | [github.com/kubewaf-io/modsecurity-proxy-wasm](https://github.com/kubewaf-io/modsecurity-proxy-wasm) |
| **Role** | Evaluate SecLang / CRS against request and response traffic |
| **Runtime** | Envoy Wasm V8 only |

This is a **standalone documentation root** for the engine project.

- **Using the engine from Kubernetes?** See the [kubeWAF docs](/docs/home/) —
  especially [WAF engine](/docs/platform/engine/).
- **Running without Kubernetes?** See [Standalone](/engines/modsecurity-proxy-wasm/standalone/).

```mermaid
flowchart LR
  R[Request] --> M[modsecurity-proxy-wasm]
  M --> UP[Upstream]
```

## Pages in this root

- **[Configuration](/engines/modsecurity-proxy-wasm/configuration/)** — Plugin JSON, virtual CRS includes, metrics, fail-closed behaviour.
- **[Standalone Envoy](/engines/modsecurity-proxy-wasm/standalone/)** — Build, run, and smoke-test without Kubernetes.

