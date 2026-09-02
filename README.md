# kubeWAF website

Website and documentation for [kubeWAF](https://github.com/kubewaf-io/kubewaf), structured like the [Kubernetes website](https://github.com/kubernetes/website):

- **Hugo Extended** + **[Docsy](https://www.docsy.dev/)** theme
- Content under `content/en/`
- Two documentation roots:
  1. **kubeWAF** (`/docs/`) — operator, CRDs, setup, concepts, tasks, tutorials, reference, contribute
  2. **Engines** (`/engines/`) — modsecurity-proxy-wasm and pow-proxy-wasm

## Prerequisites

- [Hugo Extended](https://gohugo.io/) ≥ 0.110 (site tested with 0.147)
- Node.js ≥ 20 and npm
- Go is **not** required for local preview (Docsy is installed via npm)

## Local development

```bash
# Install Docsy + PostCSS deps
make deps
# or: npm ci

# Live reload server (http://localhost:1313)
make serve
```

## Build

```bash
make build
# → public/
```

Static output is published from `public/` (GitHub Pages workflow).

## Repository layout (role-first)

```
content/en/
  _index.html                 # Marketing home
  docs/
    home/                     # Persona portal (platform / users / security)
    get-started/              # Shared orientation + quickstart
    platform/                 # Platform administrators
      providers/              # Envoy Gateway, Istio, Cilium
      observability/          # Metrics, capture, probes
    users/                    # Application teams (WAF consumers)
    security/                 # Security team (rules, SecLang, AI)
      ai/
    reference/crds/           # CRD field reference
    contribute/               # Project contributors
  engines/                    # Wasm filter deep-dives
    modsecurity-proxy-wasm/
    pow-proxy-wasm/
assets/scss/                  # Docsy brand overrides
layouts/                      # Theme overrides (e.g. mermaid for modern Hugo)
static/                       # Logos, favicons, _redirects
hugo.toml
package.json                  # docsy via npm
```

### Front matter conventions

```yaml
---
title: "Writing Security Rules"
description: "..."
weight: 10
content_type: task   # concept | task | tutorial | reference
---
```

Section indexes use `cascade: type: docs` so Docsy renders the docs sidebar.
Top nav is defined in `hugo.toml` (Documentation → `/docs/home/`, Engines).

## Content ownership

This directory is the **canonical documentation site** for the monorepo:

- kubeWAF docs: `content/en/docs/`
- Engine docs: `content/en/engines/`
- Static assets (logos, Grafana JSON, diagrams): `static/` and `assets/`

Edit markdown here directly; preview with `make serve` (or `make docs-serve` from the repo root).

## Deployment

Push to `main` triggers `.github/workflows/deploy.yml`:

1. `npm ci`
2. `hugo --gc --minify`
3. Deploy `public/` to GitHub Pages

Site: [https://kubewaf.io](https://kubewaf.io)

## Related repositories

| Project | Docs on this site | Source |
|---------|-------------------|--------|
| kubeWAF operator | [/docs/](https://kubewaf.io/docs/home/) | [kubewaf-io/kubewaf](https://github.com/kubewaf-io/kubewaf) |
| modsecurity-proxy-wasm | [/engines/modsecurity-proxy-wasm/](https://kubewaf.io/engines/modsecurity-proxy-wasm/) | [kubewaf-io/modsecurity-proxy-wasm](https://github.com/kubewaf-io/modsecurity-proxy-wasm) |
| pow-proxy-wasm | [/engines/pow-proxy-wasm/](https://kubewaf.io/engines/pow-proxy-wasm/) | [kubewaf-io/pow-proxy-wasm](https://github.com/kubewaf-io/pow-proxy-wasm) |

## License

Documentation content follows the same project license as kubeWAF unless noted otherwise.
