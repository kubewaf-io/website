---
title: Custom Resources
linkTitle: CRDs
weight: 20
description: Reference for kubeWAF Custom Resource Definitions.
content_type: reference
---

kubeWAF defines these primary CRDs:

| Kind | API group | Purpose |
|------|-----------|---------|
| [SecRule](secrule/) | `seclang.kubewaf.io` | Structured ModSecurity SecLang rules |
| [SecAction](secaction/) | `seclang.kubewaf.io` | Unconditional SecLang actions |
| [SecRuleIDPool](secruleidpool/) | `seclang.kubewaf.io` | Cluster-scoped auto IDs |
| [PhraseList](phraselist/) | `seclang.kubewaf.io` | Phrase-list bodies for `@pmFromFile` |
| [IPList](iplist/) | `seclang.kubewaf.io` | IP/CIDR list bodies for `@ipMatchFromFile` |
| [RuleSet](ruleset/) | `waf.kubewaf.io` | Composable collections of rules |
| [WAF](waf/) | `waf.kubewaf.io` | Policy attachment + engine/challenge config |

Custom list files for Path B are documented in [Phrase & IP lists](/docs/users/data-files/).
