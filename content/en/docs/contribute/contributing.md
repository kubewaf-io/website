---
title: "Contributing"
description: "How to contribute to kubeWAF documentation and code"
weight: 10
content_type: concept
---
Thank you for your interest in improving kubeWAF!

## Ways to Contribute

The operator lives in [kubewaf-io/kubewaf](https://github.com/kubewaf-io/kubewaf).
Wasm engines are **git submodules** under `engines/` (also published as their own
repos):

| Repository | Focus |
|------------|--------|
| [kubewaf-io/kubewaf](https://github.com/kubewaf-io/kubewaf) | Operator, CRDs, Helm (`kubewaf`, `kubewaf-crs`) |
| [kubewaf-io/modsecurity-proxy-wasm](https://github.com/kubewaf-io/modsecurity-proxy-wasm) | ModSecurity Wasm engine + CRS embedding |
| [kubewaf-io/pow-proxy-wasm](https://github.com/kubewaf-io/pow-proxy-wasm) | PoW challenge filter |
| [kubewaf-io/website](https://github.com/kubewaf-io/website) | This documentation site ([kubewaf.io](https://kubewaf.io)) |

- Report bugs and feature requests on the relevant repo’s Issues
- Improve documentation (this site)
- Add CRS conversions or example rules
- Write tests (unit + e2e)
- Review pull requests

## Development Environment

### Prerequisites

- Go 1.26+
- `make`, `docker`
- `kubectl` + a local cluster (kind, minikube, or k3d recommended)
- `helm`

### Setup

```bash
git clone --recurse-submodules https://github.com/kubewaf-io/kubewaf.git
cd kubewaf

make manifests generate fmt vet
make install          # installs CRDs into your cluster
make run              # runs the operator locally against your kubeconfig
```

### Useful Make Targets

| Target           | Description |
|------------------|-------------|
| `make test`      | Run unit tests |
| `make test-e2e-envoy-gateway` | PR-style e2e (Envoy Gateway smoke) |
| `make test-e2e-release` | Full release e2e (EG Path B FTW + Istio + Cilium) |
| `make test-e2e`  | Run e2e for `E2E_PROVIDER` (requires kind) |
| `make lint-fix`  | Auto-fix lint issues |
| `make crs-converter` | Build the CRS conversion tool |
| `make docker-build` | Build the operator image |

CI:

- **PR**: EG smoke (`test-e2e.yml`) **and** full matrix (`test-e2e-release.yml`)
- **main push**: EG smoke only (no full matrix)
- **tag release** (`v*`): full matrix then GoReleaser

See `test/e2e/README.md`.

## Documentation Contributions

The documentation site is **[Hugo](https://gohugo.io/)** + **[Docsy](https://www.docsy.dev/)**
in the [website](https://github.com/kubewaf-io/website) repo (local checkout is
often `website2/` next to the operator).

To preview locally:

```bash
cd website2 && make serve
```

Then open http://localhost:1313.

Content lives under `content/en/` (or `website2/content/en/` in a side-by-side
checkout). Section indexes use Hugo front matter (`title`, `weight`, `content_type`).

Docs layout (role-first):

| Path | Audience / content |
|------|--------------------|
| `docs/home/` | Persona chooser (docs portal) |
| `docs/get-started/` | Shared orientation (why, concepts, architecture, quickstart) |
| `docs/platform/` | Platform admins — install (operator + `kubewaf-crs`), providers, ECDS, webhooks, observability (metrics, capture, probes) |
| `docs/users/` | Application teams — WAF, RuleSets, PhraseList/IPList, challenge |
| `docs/security/` | Security team — SecRules, OWASP CRS, SecLang, AI expert prompt |
| `docs/reference/` | CRD field reference (WAF, SecRule, SecAction, SecRuleIDPool, PhraseList, IPList, RuleSet) |
| `docs/contribute/` | Project contributors |
| `engines/` | Wasm filter deep-dives (maintainers) |

### Style Guidelines

- Keep examples copy-pasteable
- Prefer "real" YAML over abstract snippets
- Use Docsy alert shortcodes for important caveats
- Prefer short linked lists for navigation grids (Kubernetes docs style)
- Use fenced `mermaid` code blocks for diagrams (Docsy mermaid)
- Link liberally to other pages

## Submitting Changes

1. Create a topic branch from `main`
2. Make focused commits with clear messages
3. Run `make lint-fix test` before pushing
4. Open a Pull Request

We use conventional commit style where possible (`feat:`, `fix:`, `docs:`, `chore:`).

## Documentation lives here

**All human product documentation** is this site ([kubewaf.io](https://kubewaf.io),
source [kubewaf-io/website](https://github.com/kubewaf-io/website)):

- Operator / CRD / install / security guides → `content/en/docs/`
- Wasm engine deep-dives → `content/en/engines/`

The operator repo keeps short root stubs (`README.md`, `CONTRIBUTING.md`,
`SECURITY.md`) that link here. Do not add a parallel MkDocs tree or long README
tutorials in the operator repo.

## Security reports

See [Security policy](/docs/contribute/security/) — do not file public issues for
exploitable vulnerabilities.

## Code of conduct

See [Code of conduct](/docs/contribute/code-of-conduct/) (Contributor Covenant–style).

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License that covers the project.

## Recognition

All contributors are listed in Git history. Significant contributions may also be highlighted in release notes.

Thank you for helping make Kubernetes applications safer!