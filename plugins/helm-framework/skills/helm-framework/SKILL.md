---
name: "helm-framework"
description: "Scaffold and configure Helm charts that depend on the helm-framework library chart. Use when adding helm-framework as a Helm dependency, writing values.yaml for a chart built on it, or looking up what a value controls."
---

# helm-framework

## What this skill does

Helps you add `helm-framework` (a Helm **library chart**) as a dependency of
your own chart, wire up the single template include it needs, and configure
it correctly through `values.yaml`.

Consumers never copy the library's templates — they `include` one entry
point and configure everything through their own `values.yaml`.

## Quick start

1. Add the dependency to your chart's `Chart.yaml`:

```yaml
dependencies:
  - name: helm-framework
    version: "1.3.0"
    repository: "oci://ghcr.io/k8s-stuff"
```

   Or, using the classic Helm repository instead of OCI:

```yaml
dependencies:
  - name: helm-framework
    version: "1.3.0"
    repository: "https://k8s-stuff.github.io/helm-framework"
```

2. Run `helm dependency update`.
3. Add one line to a template in your chart (e.g. `templates/deployment.yaml`):

```yaml
{{ include "helm-framework.deployment.global" . }}
```

4. Configure everything through your chart's own `values.yaml` — copy in
   only the keys you need from `resources/values-reference.md`.

## Values reference

`resources/values-reference.md` has the full, generated reference for
every configurable value, grouped into these sections:

- GLOBAL CONFIGURATION
- CONTAINER IMAGES
- POD & DEPLOYMENT CONFIGURATION
- NETWORKING
- HEALTH CHECKS & MONITORING
- SCALING & RESOURCES
- KEDA AUTOSCALING
- SECURITY
- STORAGE
- SCHEDULING
- JOBS
- LIQUIBASE DATABASE MIGRATIONS
- SIDECARS
- APPLICATION CONFIGURATION

## Worked example

`resources/example-chart.md` has a complete, working chart
(`Chart.yaml`, `values.yaml`, and the single-line template) copied from
this library's own test-template chart.

## Migrating an existing chart?

If you're moving a chart with hand-rolled templates onto `helm-framework`
rather than starting fresh, see the sibling `helm-framework-migration` skill —
it covers regression checking and orphaned-value cleanup.
