# helm-framework

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/helm-framework)](https://artifacthub.io/packages/search?repo=helm-framework)
[![Release](https://github.com/k8s-stuff/helm-framework/actions/workflows/release.yaml/badge.svg)](https://github.com/k8s-stuff/helm-framework/actions/workflows/release.yaml)
[![Lint](https://github.com/k8s-stuff/helm-framework/actions/workflows/lint.yaml/badge.svg)](https://github.com/k8s-stuff/helm-framework/actions/workflows/lint.yaml)

A Helm **library chart** that provides reusable, opinionated templates for
deploying applications on Kubernetes. Instead of copying boilerplate across
charts, depend on this library and get a production-ready Deployment/Job,
Service, Ingress, Gateway API HTTPRoute, HPA/KEDA autoscaling, PDB, VPA, TLS,
secrets management, External Secrets Operator integration, RBAC, and Istio
(AuthorizationPolicy/VirtualService) support out of the box — driven entirely
by `values.yaml`.

## Requirements

| Requirement | Version |
|-------------|---------|
| Helm        | `>= 3.x` |
| Kubernetes  | `>= 1.19` |

## Installation

### OCI Registry (recommended)

```bash
helm pull oci://ghcr.io/k8s-stuff/helm-framework --version 1.3.0
```

Or reference it directly as a dependency in your `Chart.yaml`:

```yaml
dependencies:
  - name: helm-framework
    version: "1.3.0"
    repository: "oci://ghcr.io/k8s-stuff"
```

### Classic Helm Repository

```bash
helm repo add k8s-stuff https://k8s-stuff.github.io/helm-framework
helm repo update
```

Then in your `Chart.yaml`:

```yaml
dependencies:
  - name: helm-framework
    version: "1.3.0"
    repository: "https://k8s-stuff.github.io/helm-framework"
```

## Quick Start

Add the library as a dependency in your application chart's `Chart.yaml`,
run `helm dependency update`, then render everything the library manages —
Deployment, Service, Ingress/HTTPRoute, HPA/KEDA, PDB, VPA, RBAC, secrets,
and more — with a single include in one of your own templates:

```yaml
{{- include "helm-framework.deployment.global" . }}
```

Everything is configured through your chart's `values.yaml`.

## Full Documentation

The complete, auto-generated reference for every configurable value —
kept in sync with the chart automatically by
[helm-docs](https://github.com/norwoodj/helm-docs) on every push — lives in
the chart's own README:

**[helm/helm-framework/README.md](helm/helm-framework/README.md)**

That same README ships inside the packaged chart itself (`helm show readme`
works after a `helm pull`/`helm dependency update`).

## Examples

See the [`helm/helm-framework-test-template/`](helm/helm-framework-test-template/)
directory for a working application chart that depends on this library.

## Claude Code Skill

This repo ships a [Claude Code plugin](plugins/helm-framework) with a skill
that teaches Claude how to add `helm-framework` as a dependency, wire up the
single template include, and configure it through `values.yaml` — including
the full values reference and a worked example.

Install it once in Claude Code:

```
/plugin marketplace add k8s-stuff/helm-framework
/plugin install helm-framework
```

The skill's content is regenerated from the chart's own source of truth on
every release, so it always matches the latest published version — see
[plugins/helm-framework/skills/helm-framework/SKILL.md](plugins/helm-framework/skills/helm-framework/SKILL.md).

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for
guidelines on how to develop, test, and submit changes.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE)
file for details.
