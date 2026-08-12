# Contributing to helm-framework

Thank you for your interest in contributing! This guide covers everything you
need to get started.

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) >= 3.x
- [chart-testing (`ct`)](https://github.com/helm/chart-testing#installation)
  (optional, for running the full lint suite locally)
- [helm-docs](https://github.com/norwoodj/helm-docs) (optional, for
  regenerating documentation)
- [Node.js](https://nodejs.org/) (optional, only needed to get the
  commit-message linting git hook via `npm install`)

## Development Setup

```bash
git clone https://github.com/k8s-stuff/helm-framework.git
cd helm-framework
npm install # installs the commit-msg hook that lints commit messages locally
```

## Commit Message Convention

This repo follows [Conventional Commits](https://www.conventionalcommits.org/)
and uses them to drive automated versioning — see
[Cutting a Release](#cutting-a-release). PRs are squash-merged, so the **PR
title** becomes the single commit message that lands on `main` — that's what
semantic-release actually reads, and it's what CI enforces (`PR Title Lint`)
on every pull request. Individual commits within your branch don't need to
follow the convention, though the local `commit-msg` hook (installed via
`npm install`) can help you keep them tidy too.

Examples: `feat: add PodDisruptionBudget support`,
`fix(ingress): handle empty pathType`, `docs: update README examples`.

## Running Linting Locally

Library charts cannot be linted directly because they produce no manifests.
Instead, lint through the test template chart that depends on the library:

```bash
# Update dependencies (pulls the local library chart)
helm dependency update helm/helm-framework-test-template

# Lint the test template chart
helm lint helm/helm-framework-test-template
```

To run the full chart-testing suite (same as CI):

```bash
ct lint --chart-dirs helm --all
```

## Running the Test Template Chart

You can template the test template chart to verify rendered output without a cluster:

```bash
helm dependency update helm/helm-framework-test-template
helm template my-release helm/helm-framework-test-template
```

To install on a real cluster (e.g. a local kind/minikube):

```bash
helm dependency update helm/helm-framework-test-template
helm install my-release helm/helm-framework-test-template
```

## Making Changes

1. **Fork** the repository and create a feature branch from `main`.
2. Make your changes in `helm/helm-framework/templates/` or `values.yaml`.
3. Update or add entries in `helm/helm-framework/values.yaml` for any new
   configuration knobs.
4. Run linting locally (see above) to catch issues early.
5. If you add a new template or helper, document it in the root `README.md`
   tables.
6. Update the test template chart if needed to exercise your changes.

## Cutting a Release

Releases are fully automated — there's nothing to do manually beyond merging
Conventional Commits to `main`:

1. The `Version` workflow runs [semantic-release](https://semantic-release.gitbook.io/)
   on every push to `main`. It inspects the commits since the last release
   (`fix:` → patch, `feat:` → minor, `BREAKING CHANGE:`/`!` → major), and if a
   release is warranted it generates notes, creates and pushes a `vX.Y.Z` git
   tag, and publishes a GitHub Release with those notes. It only pushes the
   tag (never a commit to `main`), so it works with the branch's
   pull-request-only ruleset without needing any bypass.
2. That tag push triggers the `Release` workflow (via an explicit
   `workflow_dispatch`, since GitHub doesn't chain runs off a
   `GITHUB_TOKEN`-authored push), which will automatically:
   - Package and push the chart to GHCR (`oci://ghcr.io/k8s-stuff/helm-framework`)
   - Package the chart again and attach the `.tgz` to that same `vX.Y.Z`
     GitHub Release semantic-release already created
   - Run `cr index` to update the `gh-pages` branch `index.yaml` for classic
     Helm repo users, pointed at that release's asset

There is deliberately only **one** release/tag per version (`vX.Y.Z`).
`chart-releaser-action`'s own `cr upload` step is not used, because it
always creates its own separate release/tag (`helm-framework-X.Y.Z` by
default) — `cr index` alone is used instead, which just reads whatever
release matches `--release-name-template` without creating anything.

The chart is packaged with `--version` set to the tag in both jobs, so the
`version` field committed in `helm/helm-framework/Chart.yaml` is not the
source of truth for releases — you don't need to bump it by hand.

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR.
- Write a clear description of **what** and **why**.
- Ensure linting passes (`helm lint` on the test template chart).
- Add or update documentation for any user-facing changes.
- Follow existing code style and naming conventions in the templates.
- If your change is breaking, note it clearly in the PR description and bump the
  major version in `Chart.yaml`.

## Reporting Issues

Please open a [GitHub Issue](https://github.com/k8s-stuff/helm-framework/issues)
with:
- A clear description of the problem or feature request
- Steps to reproduce (if it's a bug)
- Expected vs actual behaviour
- Helm and Kubernetes versions you're using

## Code of Conduct

Be respectful and constructive. We follow the
[Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
