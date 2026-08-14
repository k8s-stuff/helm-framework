---
name: "helm-framework-migration"
description: "Migrate an existing hand-rolled Helm chart onto the helm-framework library chart, check the migration for regressions, and clean up orphaned values.yaml keys. Use when moving a chart from bespoke templates to helm-framework, auditing a migration that already landed, or investigating whether a values.yaml key still does anything after such a migration."
---

# helm-framework migration

## What this skill does

Guides migrating an existing chart's hand-rolled templates onto
`helm-framework` (v1.2.0 at generation time) safely. This is a distinct,
harder job from scaffolding a new chart (see the `helm-framework` skill for
that): `helm-framework` reads the consumer's flat `.Values` directly, with no
`additionalProperties: false` enforcement, so a value nothing reads after
migration is silently ignored — the chart still renders, still deploys, and
gives no error. This skill exists to catch that failure mode before it ships.

Works both as a forward-driven migration (you are about to migrate a chart)
and as a post-hoc audit (a migration already landed and you want to check
it).

## The five phases

0. **Preflight** — check the consumer's dependency pin, this skill's own
   baked version, and the newest published version all agree. Advisory only;
   never blocks.
1. **Baseline capture** — render the chart before migrating (or, in audit
   mode, at the commit before the migration) and record the exact
   `helm template` invocation for later replay.
2. **Migration** — add the dependency, replace hand-rolled templates with
   the library's `include`, and map old value keys onto library keys using
   the `helm-framework` skill's `resources/values-reference.md`. Skipped in
   audit mode.
3. **Regression check** — replay the recorded invocation post-migration and
   diff a fixed critical-field checklist, resource-by-resource, matched by
   kind and role rather than by name.
4. **Orphan classification and cleanup** — find `values.yaml` keys nothing
   reads anymore, tier them by confidence, and auto-remove only the tier with
   a render-equality proof.

Full detail for every phase — the exact checklist, the cosmetic-churn ignore
list, the orphan tiers, and the resemblance rule used to catch near-miss
renames — is in `resources/migration-playbook.md`.

`resources/values-contract.md` is the generated, authoritative answer to
"does the library read this key?" — phase 4 depends on it.
