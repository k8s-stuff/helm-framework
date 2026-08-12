/**
 * The generated resources/values-contract.md for the migration skill.
 */
export function buildValuesContractMarkdown({ chartName, version, readSet, valueTree }) {
  const readList = readSet.map((k) => `- \`${k}\``).join('\n');
  const treeList = valueTree.map((p) => `- \`${p}\``).join('\n');
  return `# ${chartName} values contract (v${version})

Generated from \`helm/helm-framework/templates/\` and \`helm/helm-framework/values.yaml\`.
Do not edit by hand. This is what the migration playbook uses to classify a
consumer's leftover \`values.yaml\` keys as read, unread, or unknown.

## Top-level keys are authoritative

The list below comes from grepping \`.Values.<name>\` across every template in
\`helm/helm-framework/templates/\`. It is the exact set of top-level keys the
library reads, and generation fails if it ever disagrees with
\`values.yaml\`'s own top-level keys (an explicit allowlist covers deliberate
exceptions). Treat this list as ground truth: a top-level consumer key that
is **not** in this list is not read by the library, full stop.

${readList}

## Nested paths are declared-surface only — not grep-verified

The list below is \`values.yaml\`'s own declared key tree (dotted paths,
derived from indentation). Unlike the top-level list above, **this is not a
readership proof.**

Why: deep access inside the library frequently goes through helper indirection,
e.g. \`include "helm-framework.values.service.port"\` rather than a literal
\`.Values.service.port\` appearing in a template. Grepping for a literal nested
path is therefore provably incomplete — it misses every value read through a
helper. So:

- a nested path appearing here is *plausible*, but not proven read
- a nested path missing here may still be legitimately consumed by its
  top-level parent through a helper

**Do not auto-remove a consumer's nested key on the strength of this list
alone.** The migration playbook only auto-removes what it can also prove via
a byte-identical re-render — this list is for reasoning about plausibility,
not for authorizing deletion.

${treeList}
`;
}

/**
 * The generated skills/helm-framework-migration/SKILL.md.
 */
export function buildMigrationSkillMarkdown({ chartName, version }) {
  return `---
name: "${chartName}-migration"
description: "Migrate an existing hand-rolled Helm chart onto the ${chartName} library chart, check the migration for regressions, and clean up orphaned values.yaml keys. Use when moving a chart from bespoke templates to ${chartName}, auditing a migration that already landed, or investigating whether a values.yaml key still does anything after such a migration."
---

# ${chartName} migration

## What this skill does

Guides migrating an existing chart's hand-rolled templates onto
\`${chartName}\` (v${version} at generation time) safely. This is a distinct,
harder job from scaffolding a new chart (see the \`${chartName}\` skill for
that): \`${chartName}\` reads the consumer's flat \`.Values\` directly, with no
\`additionalProperties: false\` enforcement, so a value nothing reads after
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
   \`helm template\` invocation for later replay.
2. **Migration** — add the dependency, replace hand-rolled templates with
   the library's \`include\`, and map old value keys onto library keys using
   the \`${chartName}\` skill's \`resources/values-reference.md\`. Skipped in
   audit mode.
3. **Regression check** — replay the recorded invocation post-migration and
   diff a fixed critical-field checklist, resource-by-resource, matched by
   kind and role rather than by name.
4. **Orphan classification and cleanup** — find \`values.yaml\` keys nothing
   reads anymore, tier them by confidence, and auto-remove only the tier with
   a render-equality proof.

Full detail for every phase — the exact checklist, the cosmetic-churn ignore
list, the orphan tiers, and the resemblance rule used to catch near-miss
renames — is in \`resources/migration-playbook.md\`.

\`resources/values-contract.md\` is the generated, authoritative answer to
"does the library read this key?" — phase 4 depends on it.
`;
}

/**
 * The generated resources/migration-playbook.md.
 */
export function buildMigrationPlaybookMarkdown({ chartName, version }) {
  return `# ${chartName} migration playbook

Full detail for each of the five phases summarized in \`SKILL.md\`. Generated
for version \`${version}\` — the version baked into Phase 0's comparison below.

## Phase 0 — Preflight (version currency)

Before touching anything, compare three versions:

1. The consumer's own dependency pin in \`Chart.yaml\`
   (\`dependencies[].version\` for \`${chartName}\`).
2. The version this skill was generated against: \`${version}\`.
3. The newest published version, resolved in this order:
   - \`helm show chart oci://ghcr.io/k8s-stuff/${chartName}\`
   - falling back to the gh-pages index (\`helm repo add\` + \`helm search repo
     --versions\`)
   - falling back to \`gh release list\`

Three outcomes:

- **newest > \`${version}\` (this skill's own baked version)** — the installed
  plugin is stale. Tell the user to update the plugin before proceeding, and
  warn explicitly that this playbook may not know about values added in
  newer releases.
- **pin < newest** — bump the dependency *before* migrating, so the
  migration work isn't done twice against two different contracts.
- **every lookup failed** — degrade to comparing the pin against \`${version}\`
  only, and state plainly that the upper bound could not be verified.

**Preflight advises; it never blocks.** Report what you found and proceed
regardless — none of these outcomes is a reason to refuse the migration.

## Phase 1 — Baseline capture

Render the chart before anything changes, in one of two modes:

**Forward mode** (migrating now): refuse to capture a baseline on a dirty
working tree. Uncommitted changes poison the diff — there would be no way
to tell whether a phase 3 difference came from the migration or from
whatever was already uncommitted. Ask the user to commit or stash first.

**Audit mode** (checking a migration that already landed): locate the
migration commit, then \`git worktree add\` its *parent* commit into a
scratch directory, run \`helm dependency build\` there, and render from that
worktree.

Whichever mode: **record the exact \`helm template\` invocation** — release
name, namespace, every \`-f\` values file, every \`--set\`. Phase 3 must replay
this identically. A differing invocation (a missing \`-f\`, a different
\`--set\`) produces a diff between two different configurations, not a diff of
the migration — and that diff means nothing.

## Phase 2 — Migration

Brief, because the mechanics match scaffolding a new chart — see the
\`${chartName}\` skill's \`resources/values-reference.md\` for the full value
catalogue:

1. Add \`${chartName}\` to \`Chart.yaml\` \`dependencies\`, run
   \`helm dependency update\`.
2. Replace the hand-rolled templates with
   \`{{ include "${chartName}.deployment.global" . }}\`.
3. Map every old value key onto its library equivalent in the consumer's own
   \`values.yaml\`, using \`values-reference.md\` as the reference for what the
   library actually reads and how it's named.

Skipped entirely in audit mode — there the migration already happened; this
playbook is only checking it.

## Phase 3 — Regression check

Replay the phase 1 invocation exactly, against the post-migration chart.
Match resources across the before/after renders **by kind and role, not by
name** — library naming conventions and \`fullnameOverride\` commonly rename
resources during a migration, so a name-based diff would report a rename as
a delete-and-create instead of comparing the two like-for-like.

For each matched resource pair, compare this fixed critical-field checklist
and report each field \`OK\`, \`CHANGED\`, or \`LOST\`:

- replicas
- image
- command/args
- env vars
- envFrom
- container ports
- resource requests and limits
- liveness/readiness/startup probes
- affinity
- volumes and volumeMounts
- securityContext and podSecurityContext
- serviceAccount
- service type and ports
- ingress hosts and paths
- PodDisruptionBudget
- HPA min/max bounds

\`affinity\` is on this checklist because validation surfaced a real
scheduling-behaviour change no other row would catch: the library injects a
default \`podAntiAffinity\` block that is absent pre-migration.

**Verdict granularity.** One verdict per checklist row. Several rows are
composite — \`serviceAccount\` covers name, annotations, and automount;
\`service type and ports\` covers the service \`type\` plus every port entry —
and the convention is the same for all of them: if any sub-field within the
row differs, the row is \`CHANGED\`, and the report names the specific
differing sub-field(s) rather than just the row label.

**Ignore list** — cosmetic churn a template-library migration legitimately
causes, and which is never worth reporting as a regression:

- labels
- annotations
- checksum annotations
- generated resource names

Phase 3 finds symptoms (a field is \`LOST\`); phase 4 usually names the cause
(the \`values.yaml\` key that used to set it). Read them together.

## Phase 4 — Orphan classification and cleanup

Enumerate key paths across **every** values file the phase 1 invocation
uses — not just \`values.yaml\`. A key can be absent from \`values.yaml\` and
live only in an overlay such as \`values-prod.yaml\`, and it is exactly as
orphanable there.

From that enumerated set, subtract every legitimate reader:

- every key in \`resources/values-contract.md\`
- keys still grepped as \`.Values.*\` from the consumer's own remaining
  templates (post-migration, a consumer chart may still have templates of
  its own)
- subchart names declared in the consumer's \`Chart.yaml\`
- \`global\`

What remains is tiered, evaluated **in this order: CONFIRMED, LIKELY MISS,
UNPROVABLE**:

| Tier | Definition | Action |
|---|---|---|
| CONFIRMED | Top-level, no reader anywhere, and removing it leaves the render byte-identical | Auto-removed |
| LIKELY MISS | Resembles a real library key under the matching rule below | Never removed; reported loudly — this is a silently lost setting |
| UNPROVABLE | Nested-only, a subchart or \`global\` key, a YAML anchor target, or plausibly read by Argo CD/CI tooling outside Helm | Reported, left alone |

### The resemblance rule

**Matching is against every leaf segment of every contract path, not just
top-level contract keys — stated explicitly and prominently because the two
readings produce opposite, safety-relevant outcomes for the same key.** The
values contract lists both top-level keys (\`healthChecks\`) and nested
declared paths (\`healthChecks.livenessProbe\`, \`healthChecks.readinessProbe\`,
...). A candidate orphan key must be compared against **every** leaf name
appearing anywhere in the contract — the last segment of
\`healthChecks.livenessProbe\` is \`livenessProbe\`, and that leaf is a
legitimate match target in its own right, independent of whether
\`healthChecks\` itself matches.

Read narrowly (top-level keys only), an orphaned \`livenessProbe\` key fails
every clause below against the top-level key \`healthChecks\` and is wrongly
classified CONFIRMED — the only evidence that a health-check setting was lost
in migration then gets silently deleted. Read correctly (leaf-of-any-path),
\`livenessProbe\` exact-matches the leaf of \`healthChecks.livenessProbe\` under
clause 1 below and correctly lands in LIKELY MISS. **Leaf-segment matching is
the only correct reading; top-level-only matching is a defect, not a
simplification.**

A candidate key counts as resembling a contract key — and so is pulled into
LIKELY MISS rather than CONFIRMED — when **any** of these hold against some
leaf segment of some path in the values contract:

1. the two names are equal after lowercasing and stripping all
   non-alphanumeric characters (\`pod_annotations\` vs \`podAnnotations\`;
   \`livenessProbe\` vs the leaf of \`healthChecks.livenessProbe\`)
2. one name is a prefix of the other, and the shared prefix is at least four
   characters long (\`replicas\` vs \`replicaCount\`, \`env\` vs \`envVars\`)
3. the pair appears in this seeded alias table of known legacy spellings:

   | Legacy key | Library key |
   |---|---|
   | \`replicas\` | \`replicaCount\` |
   | \`env\` | \`envVars\` |
   | \`envFrom\` | \`envVarsFromSecret\` |
   | \`probes\` | \`healthChecks\` |
   | \`livenessProbe\` | \`healthChecks.livenessProbe\` |
   | \`readinessProbe\` | \`healthChecks.readinessProbe\` |
   | \`startupProbe\` | \`healthChecks.startupProbe\` |
   | \`annotations\` | \`podAnnotations\` |
   | \`labels\` | \`podLabels\` |
   | \`hpa\` | \`horizontalPodAutoscaler\` |
   | \`vpa\` | \`verticalPodAutoscaler\` |
   | \`pdb\` | \`podDisruptionBudget\` |

**A resemblance match always wins over the render proof.** Even when
removing the candidate key leaves the render byte-identical, a resemblance
match pulls it out of CONFIRMED and into LIKELY MISS. A no-op render is
exactly what a silently lost setting looks like — the whole reason this key
is dangerous is that the value it used to control quietly stopped applying,
so of course removing it changes nothing. Never let the render proof
override a resemblance match.

### Worked example — the defect this rule exists to catch

A consumer's leftover \`values.yaml\` has an orphaned top-level \`livenessProbe\`
key — the common legacy spelling; the library reads
\`healthChecks.livenessProbe\` instead. Walk it through classification:

1. **Orphan found.** Nothing in the values contract's top-level list, no
   template still grepped from the consumer's own chart, no subchart name,
   not \`global\` — \`livenessProbe\` is an orphan candidate.
2. **Render proof.** Removing it and re-rendering produces a byte-identical
   result. Read naively, that looks like grounds for CONFIRMED.
3. **Leaf-segment match fires first.** \`livenessProbe\` is compared against
   every leaf in the contract, including the leaf of
   \`healthChecks.livenessProbe\`. Clause 1 (equal after normalizing) matches
   exactly.
4. **Verdict: LIKELY MISS.** The resemblance match wins over the render
   proof. The key is reported loudly as a likely lost health-check setting
   and is **not** removed — despite the byte-identical re-render that would
   otherwise have promoted it straight to CONFIRMED and auto-deleted it.

This is exactly the failure this feature exists to prevent: a silently lost
setting whose only remaining evidence is the orphaned key itself.

## Safety invariants

**Auto-removal requires the byte-identical re-render proof.** Anything that
prevents rendering collapses this feature to report-only — it never
guesses.

**Phase-3/phase-4 cross-check.** A field the phase 3 checklist reported
\`CHANGED\` or \`LOST\` whose controlling \`values.yaml\` key phase 4 is about to
classify CONFIRMED is a contradiction — a render-equality proof says removing
the key changes nothing, yet phase 3 just observed that something it
controls did change. That contradiction blocks auto-removal: downgrade the
key to LIKELY MISS and report it, exactly as if the resemblance rule itself
had fired. This is a second, independent net, distinct from leaf-segment
matching above — it would have caught the \`livenessProbe\` case earlier in
this document on its own, because phase 3 would have reported the
liveness/readiness/startup probes row as \`CHANGED\` or \`LOST\` for the very
resource whose \`values.yaml\` key phase 4 was about to confirm for removal.

Concretely:

| Situation | Behaviour |
|---|---|
| Registry lookup unavailable (phase 0) | Degrade to pin-vs-skill-version comparison; state the upper bound is unverified |
| Dirty working tree, forward mode (phase 1) | Refuse to capture a baseline; ask the user to commit or stash |
| Audit mode cannot find the migration commit (phase 1) | Ask the user for the base ref rather than guessing one |
| \`helm template\` fails on the **before** side (phase 3) | No baseline exists. Skip phase 3 entirely; run phase 4 static-only (contract-and-grep classification, no render proof). Nothing reaches CONFIRMED, so nothing is auto-removed |
| \`helm template\` fails on the **after** side (phase 3) | Hard stop. The migration itself is broken — fix that before doing anything else |

Two \`values.yaml\` hazards, both of which can corrupt a consumer's file if
handled carelessly:

- **Formatting.** A CONFIRMED removal is a surgical line-range edit against
  the original file text, **never** a YAML parse-and-rewrite. A round-trip
  through a YAML parser would strip comments and reflow formatting,
  producing a diff nobody could review and potentially losing content that
  was never orphaned.
- **Anchors.** A key that is a YAML anchor target (\`&name\`) referenced
  elsewhere in the file (\`*name\`) is UNPROVABLE regardless of what reads it
  through Helm — deleting the anchor breaks every alias that points at it,
  even if nothing in \`${chartName}\` itself ever read that key.
`;
}
