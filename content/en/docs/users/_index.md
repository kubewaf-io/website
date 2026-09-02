---
title: Application teams
linkTitle: Application teams
main_menu: false
weight: 40
description: >
  Protect your services with a WAF resource — attach gateways, consume RuleSets,
  and optional challenges.
content_type: concept
cascade:
  type: docs
---

You own an application (or a set of services) and need HTTP protection in front of it.
The platform team has already installed kubeWAF; you author **`WAF`** (and sometimes
**RuleSet**) resources in your namespace.

{{% pageinfo %}}
**Writing custom SecRules or designing org-wide rule packs?** See
[Security team](/docs/security/).  
**Installing the operator or wiring Istio/Envoy Gateway?** See
[Platform](/docs/platform/).
{{% /pageinfo %}}

## What you own

| Goal | Page |
|------|------|
| End-to-end first protection | [Protect a service](protect-a-service/) |
| Group and attach rules | [Using RuleSets](rulesets/) |
| Custom phrase / IP list files | [Phrase & IP lists](data-files/) |
| Dry-run a request | [Probes](/docs/platform/observability/probes/) |
| Metrics and eval traces | [Observability](/docs/platform/observability/) |
| Bot / scraper friction | [Proof-of-work challenge](challenge/) |

Platform installs the operator (and optional `kubewaf-crs`). Security owns
[OWASP CRS](/docs/security/using-crs/) attach and tuning.

## Recommended path

1. Confirm the operator is installed ([Installation](/docs/platform/installation/) if you also run the cluster).  
2. Follow [Protect a service](protect-a-service/) or [Quick start](/docs/get-started/quickstart/).  
3. Attach shared packs via [RuleSets](rulesets/). For a CRS baseline, ask
   security (or follow [OWASP CRS](/docs/security/using-crs/)).  
4. Optional: [Challenge](challenge/) in front of expensive WAF evaluation.
