---
title: Reference
linkTitle: Reference
main_menu: false
weight: 60
description: CRD and API reference for kubeWAF resources.
content_type: concept
cascade:
  type: docs
---

Look up Custom Resource fields and relationships.

| Resource | Purpose |
|----------|---------|
| [SecRule](crds/secrule/) | Single security check |
| [SecAction](crds/secaction/) | Unconditional SecLang action |
| [SecRuleIDPool](crds/secruleidpool/) | Auto IDs when `metadata.id` is omitted |
| [PhraseList](crds/phraselist/) | Phrase bodies for `@pmFromFile` |
| [IPList](crds/iplist/) | IP/CIDR bodies for `@ipMatchFromFile` |
| [RuleSet](crds/ruleset/) | Reusable rule collections |
| [WAF](crds/waf/) | Attach protection to a gateway / workload path |

Dry-run a request against assembled rules: [Probes](/docs/platform/observability/probes/).

For **how to write** rules (not field lists), see [Security team](/docs/security/) —
especially [SecLang structure](/docs/security/seclang-structure/) and
[Writing security rules](/docs/security/writing-rules/).
