---
title: kubeWAF Documentation
linkTitle: Documentation Home
main_menu: false
weight: 10
no_list: true
description: >
  Role-oriented documentation for platform administrators, application teams,
  and security engineers using kubeWAF.
aliases:
  - "/docs/kubewaf/"
  - "/docs/kubewaf/index.html"
  - "/docs/index.html"
---

{{% alert title="Beta — v0.1.0-beta.1" color="warning" %}}
kubeWAF is in **beta** (`v1beta1` APIs). Expect change; start with
[Beta status](/docs/get-started/beta/) and **DetectionOnly** mode for first CRS rollouts.
{{% /alert %}}

kubeWAF defines WAF policy as version-controlled Custom Resources and enforces it inside Envoy —
across **Envoy Gateway**, **Istio**, and **Cilium**. Rules are ModSecurity-compatible SecLang
(structured YAML) plus optional **OWASP CRS**.

Pick the path that matches **your job**. Shared concepts and API reference sit alongside
role guides.

## Choose your path

<div class="row docs-portal g-4 mt-2">
  <div class="col-md-6 col-lg-4">
    <div class="card h-100 p-3">
      <h3 class="h5 card-title">Platform administrators</h3>
      <p class="card-text small text-muted">
        Install the operator, deliver Wasm modules, wire gateway providers, and operate
        cluster-wide observability.
      </p>
      <ul class="small mb-3">
        <li><a href="/docs/platform/installation/">Installation (Helm)</a></li>
        <li><a href="/docs/platform/providers/envoy-gateway/">Envoy Gateway</a></li>
        <li><a href="/docs/platform/observability/">Observability</a> · <a href="/docs/platform/observability/capture/">Capture</a> · <a href="/docs/platform/observability/probes/">Probes</a></li>
      </ul>
      <a class="btn btn-sm btn-primary" href="/docs/platform/">Platform guide</a>
    </div>
  </div>
  <div class="col-md-6 col-lg-4">
    <div class="card h-100 p-3">
      <h3 class="h5 card-title">Application teams</h3>
      <p class="card-text small text-muted">
        Protect your services with a <code>WAF</code> resource — RuleSets and
        optional proof-of-work challenge.
      </p>
      <ul class="small mb-3">
        <li><a href="/docs/users/protect-a-service/">Protect a service</a></li>
        <li><a href="/docs/users/rulesets/">Using RuleSets</a></li>
        <li><a href="/docs/users/challenge/">PoW challenge</a></li>
      </ul>
      <a class="btn btn-sm btn-primary" href="/docs/users/">Application guide</a>
    </div>
  </div>
  <div class="col-md-6 col-lg-4">
    <div class="card h-100 p-3">
      <h3 class="h5 card-title">Security team</h3>
      <p class="card-text small text-muted">
        Author SecRules and org-wide packs, tune CRS, and use AI-assisted rule writing
        with validation.
      </p>
      <ul class="small mb-3">
        <li><a href="/docs/security/writing-rules/">Writing security rules</a></li>
        <li><a href="/docs/security/using-crs/">OWASP CRS</a></li>
        <li><a href="/docs/security/seclang-structure/">SecLang structure</a></li>
        <li><a href="/docs/security/ai/">AI assistance</a></li>
      </ul>
      <a class="btn btn-sm btn-primary" href="/docs/security/">Security guide</a>
    </div>
  </div>
  <div class="col-md-6 col-lg-4">
    <div class="card h-100 p-3">
      <h3 class="h5 card-title">Get started</h3>
      <p class="card-text small text-muted">
        Shared orientation — why kubeWAF, core abstractions, architecture, and a
        quick first install path.
      </p>
      <ul class="small mb-3">
        <li><a href="/docs/get-started/beta/">Beta status</a></li>
        <li><a href="/docs/get-started/why-kubewaf/">Why kubeWAF?</a></li>
        <li><a href="/docs/get-started/core-concepts/">Core concepts</a></li>
        <li><a href="/docs/get-started/quickstart/">Quick start</a></li>
      </ul>
      <a class="btn btn-sm btn-outline-primary" href="/docs/get-started/">Get started</a>
    </div>
  </div>
  <div class="col-md-6 col-lg-4">
    <div class="card h-100 p-3">
      <h3 class="h5 card-title">API reference</h3>
      <p class="card-text small text-muted">
        CRD field reference for WAF, SecRule, RuleSet, list files, and related types.
      </p>
      <ul class="small mb-3">
        <li><a href="/docs/reference/crds/waf/">WAF</a></li>
        <li><a href="/docs/reference/crds/secrule/">SecRule</a> / <a href="/docs/reference/crds/secaction/">SecAction</a></li>
        <li><a href="/docs/reference/crds/ruleset/">RuleSet</a> / <a href="/docs/reference/crds/secruleidpool/">SecRuleIDPool</a></li>
        <li><a href="/docs/reference/crds/phraselist/">PhraseList</a> / <a href="/docs/reference/crds/iplist/">IPList</a></li>
        <li><a href="/docs/platform/observability/probes/">Probes</a></li>
      </ul>
      <a class="btn btn-sm btn-outline-primary" href="/docs/reference/">View reference</a>
    </div>
  </div>
  <div class="col-md-6 col-lg-4">
    <div class="card h-100 p-3">
      <h3 class="h5 card-title">Contribute &amp; engines</h3>
      <p class="card-text small text-muted">
        Improve the operator or dive into Wasm filter internals (maintainers).
      </p>
      <ul class="small mb-3">
        <li><a href="/docs/contribute/contributing/">Contributing</a></li>
        <li><a href="/docs/contribute/security/">Security policy</a></li>
        <li><a href="/docs/platform/engine/">Engine matrix</a></li>
        <li><a href="/engines/modsecurity-proxy-wasm/">modsecurity-proxy-wasm</a></li>
        <li><a href="/engines/pow-proxy-wasm/">pow-proxy-wasm</a></li>
      </ul>
      <a class="btn btn-sm btn-outline-primary" href="/docs/contribute/">Contribute</a>
    </div>
  </div>
</div>
