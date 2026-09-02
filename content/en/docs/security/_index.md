---
title: Security team
linkTitle: Security
main_menu: false
weight: 50
description: >
  Author detection policy — SecRules, RuleSet design, CRS tuning, SecLang structure,
  and AI-assisted rule writing.
content_type: concept
cascade:
  type: docs
---

You define **what** gets blocked or scored: custom virtual patches, RuleSet packs for
the organization, CRS paranoia and exclusions, and review standards for policy PRs.

{{% pageinfo %}}
Application teams **consume** your packs via `WAF.ruleRefs` —
see [Application teams](/docs/users/). Platform sets install and tenancy —
see [Platform](/docs/platform/).
{{% /pageinfo %}}

## What you own

| Goal | Page |
|------|------|
| Write SecRules (structured + raw SecLang) | [Writing security rules](writing-rules/) |
| Enable and tune OWASP CRS | [OWASP CRS](using-crs/) |
| Dry-run a request against a rule | [Probes](/docs/platform/observability/probes/) |
| Eval traces / capture | [Capture](/docs/platform/observability/capture/) |
| SecLang YAML model | [SecLang structure](seclang-structure/) |
| Phrase / IP list files (`@pmFromFile`, `@ipMatchFromFile`) | [Phrase & IP lists](/docs/users/data-files/) |
| Compose reusable packs | [Using RuleSets](/docs/users/rulesets/) |
| AI-assisted authoring | [AI assistance](ai/) |

## Recommended path

1. Skim [Core concepts](/docs/get-started/core-concepts/) (`SecRule` / `RuleSet` / `WAF`).  
2. [Writing security rules](writing-rules/) — prefer anomaly scoring + high rule IDs.  
3. Keep the [expert prompt](ai/kubewaf-secrule-expert/) in your AI tooling.  
4. Attach and tune [OWASP CRS](using-crs/) (platform installs the `kubewaf-crs` chart).  
5. Publish packs as RuleSets.
