# Native Liquibase migration support

Date: 2026-08-27
Status: Approved design, not yet implemented

## Problem

Charts that need a database migration to complete before their pods start
currently hand-roll the whole mechanism. The reference case is
`spark-customer-webhooks-agentcontainer`, which carries its own singular
`job:` values block, its own `rolePodUpdater` RBAC, its own
`initContainer.waitForEnabled` flag, two ConfigMap templates (changelog and
migration SQL), and a Secret template for the Liquibase connection
environment — none of which the framework can express.

The framework already provides most of the underlying machinery:

- `jobs[]` renders one pre-install/pre-upgrade hook Job per enabled entry
  (`templates/_job.yaml`).
- `waitForIt: true` on a job entry renders a `kubectl wait` init container in
  the Deployment, auto-provisions a `<fullname>-wait-for-jobs` Role and
  RoleBinding, and forces `automountServiceAccountToken`
  (`templates/_deployment.yaml`, `_role.tpl`, `_helpers.tpl`,
  `_serviceaccount.tpl`).

What is missing is Liquibase-shaped: JDBC URL composition, credential
plumbing, ConfigMaps for the changelog and migration files, and image /
command defaults. There is no ConfigMap template in the framework at all
today.

## Goals

- A consuming chart declares a `liquibase:` block and gets a complete,
  correct pre-start migration: Job, changelog ConfigMap, migrations
  ConfigMap, connection Secret, and the wait-for-job init container that
  blocks the Deployment until the migration completes.
- Migration SQL lives as real files in the consuming chart, not as YAML
  blobs.
- Credentials have a supported path to an external secret manager, not only
  plaintext values.
- No regression to the existing `jobs[]` path.

## Non-goals

- Tool neutrality. This is deliberately Liquibase-specific; a
  `dbMigration.tool` abstraction was considered and rejected as premature.
- Framework knowledge of any JDBC driver: no engine list, no default ports, no
  built-in URL templates. The chart author supplies the URL or its printf
  shape, and the framework substitutes and stops there.
- Rollback, diff, or any Liquibase command beyond what `command`/`args`
  expose.

## Verified assumptions

`.Files` inside a library-chart template resolves to the **consuming**
chart's files, because the consuming chart's `templates/deployment.yaml`
passes its own root context (`.`) into the library `include`. Verified with a
throwaway two-chart probe: a library template rendered from a parent chart
read the parent's `liquibase/changelog.xml` via `.Files.Get` and enumerated
`liquibase/migrations/*.sql` via `.Files.Glob`, with `base $path` yielding
clean ConfigMap keys. This is the foundation of the file-sourced design
below.

## Values API

```yaml
liquibase:
  enabled: false
  name: liquibase             # suffix for Job/ConfigMap/Secret names
  waitForIt: true             # block the Deployment until the Job completes
  restartPolicy: OnFailure
  backoffLimit: 6
  image:
    repository: liquibase/liquibase
    tag: "4.33"
    pullPolicy: IfNotPresent
  command: ["liquibase"]
  args: ["update", "--changeLogFile=changelog.xml"]
  log:
    level: INFO               # SEVERE WARNING INFO FINE OFF
  database:
    url: ""                   # literal JDBC URL, tpl-rendered; wins over urlTemplate
    urlTemplate: ""           # printf, exactly three %s: host, port, name
    host: ""                  # required when urlTemplate is used
    port: 0                   # required when urlTemplate is used; no default
    name: ""                  # required when urlTemplate is used
    userName: ""
    password: ""
    existingSecret:
      name: ""                # when set, credentials come from secretKeyRef
      usernameKey: username
      passwordKey: password
  changelog:
    file: ""                  # path within the consuming chart
    content: ""               # inline alternative; `file` wins if both set
    mountPath: /liquibase/changelog.xml
  migrations:
    paths: []                 # globs within the consuming chart
    files: {}                 # inline alternative: filename -> content
    mountPath: /liquibase/migrations
  resources: {}               # falls back to .Values.resources; VPA-aware
  extraEnvVars: []
  extraEnvFrom: []            # tpl-rendered
  volumes: []
  volumeMounts: []
```

### No per-engine defaults

**Revised during PR review (#9).** An earlier revision of this design had a
`database.engine` enum (`sqlserver` / `postgresql` / `mysql` / `oracle`)
selecting a default port and a built-in JDBC URL template. That is removed.
Two objections, both sound:

- A closed enum in a library chart's public API is a liability. Every driver
  the framework does not list is a chart that cannot express itself without an
  escape hatch, and adding, renaming, or correcting an entry later is a
  behaviour change for every chart pinned to it — a breaking change dressed up
  as a default.
- Baked-in URL templates hide the connection string from the chart author.
  Real deployments carry vendor-specific parameters (`encrypt`,
  `trustServerCertificate`, `oracle.net.ssl_server_dn_match`, connection-pool
  and timeout options); a fixed three-substitution template silently cannot
  express them, and the failure shows up at migration time, not render time.

The framework therefore ships **no** knowledge of any driver. The chart author
always writes the URL shape, one of two ways:

| Value | Shape | When |
|---|---|---|
| `database.url` | a literal JDBC URL, `tpl`-rendered | any driver, any vendor-specific parameter; the framework never parses or rewrites it |
| `database.urlTemplate` | named placeholders `{host}`, `{port}`, `{name}` | keeps host/port/name as separate values, so a per-environment overlay can change just the host |

`url` wins when both are set. Neither has a default, so one is always
required — enforced by validation rather than guessed.

Common templates, documented in `values.yaml` as examples rather than
implemented as code:

```
SQL Server: jdbc:sqlserver://{host}:{port};database={name};
PostgreSQL: jdbc:postgresql://{host}:{port}/{name}
MySQL:      jdbc:mysql://{host}:{port}/{name}
Oracle:     jdbc:oracle:thin:@{host}:{port}/{name}
```

Note that the SQL Server example omits `encrypt=false`: a chart that needs
transport encryption relaxed writes it into its own `urlTemplate`, where it is
visible in that chart's values and in review.

### Why the placeholders are named, not positional

**Revised during PR review (#9).** `urlTemplate` was first specified as a
`printf` template taking three `%s` verbs filled with host, port, name in that
order, and validation checked that exactly three verbs were present. A reviewer
pointed out the hole: verb *count* is checkable, verb *meaning* is not. A
template written `jdbc:custom:%s@%s:%s` intending name/host/port receives
host/port/name, yielding `jdbc:custom:sql-server@1433/MyStore` — a
syntactically valid URL that renders cleanly, passes validation, and fails only
when Liquibase tries to connect. Exactly the silent-failure class the rest of
this design goes out of its way to catch at render time.

Named placeholders cannot be mis-ordered, and they compose better: each is
independently optional, so a driver URL needing only host and port simply omits
`{name}`. Substitution is `replace`, not `printf`.

The cost is that charts migrating from a hand-rolled printf
`connectionStringTemplate` must rewrite `%s` into named placeholders rather
than renaming the key. Validation makes that a render-time error with the
rewrite spelled out, rather than a wrong URL: a `%s`, `%d`, `%v` or `%q` verb
anywhere in `urlTemplate` is rejected outright.

Full `urlTemplate` validation:

- printf verbs (`%s`/`%d`/`%v`/`%q`) rejected, with the named-placeholder
  rewrite shown.
- Unknown placeholders rejected — `{database}` and `{dbname}` are the obvious
  near-misses — listing the supported set and pointing at `database.url` for
  anything else.
- A template with no placeholders at all rejected: it would render as a
  constant, so `database.url` is the right home for it.
- Every placeholder actually used must have its value set; the message names
  which. Placeholders *not* used impose no requirement.

The supported placeholder names live in one helper,
`helm-framework.liquibase.urlTemplate.placeholders`, read by both the URL
composer and the validation, so the two cannot disagree about what is legal.

### Composed environment

The Job container receives:

| Variable | Source |
|---|---|
| `LIQUIBASE_COMMAND_URL` | plain `value:`, composed as above |
| `LIQUIBASE_COMMAND_USERNAME` | `secretKeyRef` — the generated Secret, or `existingSecret` when set |
| `LIQUIBASE_COMMAND_PASSWORD` | `secretKeyRef` — the generated Secret, or `existingSecret` when set |
| `LIQUIBASE_LOG_LEVEL` | `log.level` |
| `LIQUIBASE_SEARCH_PATH` | `dir changelog.mountPath` (so `/liquibase` by default), making the default `--changeLogFile=changelog.xml` resolve against the mount even if `mountPath` is overridden |

The URL is a plain `value:` rather than a Secret key: a JDBC URL is a
connection target, not a credential, and keeping it in the pod spec makes
`kubectl describe job` diagnostic. Only the username and password are
Secret-sourced. Consequently the generated Secret holds exactly two keys,
`LIQUIBASE_COMMAND_USERNAME` and `LIQUIBASE_COMMAND_PASSWORD`, and is skipped
entirely when `existingSecret.name` is set.

`extraEnvVars` is appended, and `extraEnvFrom` is passed through `tpl` so it
can reference other helpers (matching how the reference chart references a
Secret name through an `include`).

## Rendered resources

All are Helm hooks, so they are created before the release's main manifests.
Hook weights matter: the ConfigMaps and Secret must exist before the Job
pod starts.

| Template file | Define | Resource | Hook weight |
|---|---|---|---|
| `_liquibase.tpl` | `helm-framework.deployment.liquibase` | Job `<fullname>-<name>` | `-10` |
| `_configmap-liquibase.tpl` | `helm-framework.deployment.liquibase-configmaps` | ConfigMaps `<fullname>-<name>-changelog`, `<fullname>-<name>-migrations` | `-20` |
| `_secret-liquibase.tpl` | `helm-framework.deployment.liquibase-secret` | Secret `<fullname>-<name>-env` | `-20` |

The Secret is skipped entirely when `database.existingSecret.name` is set.
Each define is added to `$documents` in `_deployment-global.tpl`.

The migrations ConfigMap is skipped when neither `migrations.paths` nor
`migrations.files` yields anything, since a self-contained changelog is
valid. The changelog ConfigMap is always rendered when `enabled`.

ConfigMap keys are `base $path` for globbed files and the map key for inline
files, so `liquibase/migrations/001_init.sql` mounts as
`/liquibase/migrations/001_init.sql`.

When both `migrations.paths` and `migrations.files` are set, the two sources
are merged into one ConfigMap and globbed files win on key collision —
matching the changelog precedence, where `file` beats `content`. Files on
disk are the source of truth in both cases.

### Name helpers

Added to `_helpers.tpl`, so consuming charts and the templates share one
definition of every generated name:

| Helper | Returns |
|---|---|
| `helm-framework.liquibase.enabled` | `"true"` when `liquibase.enabled` |
| `helm-framework.liquibase.job-name` | `<fullname>-<name>` |
| `helm-framework.liquibase.changelog-configmap-name` | `<fullname>-<name>-changelog` |
| `helm-framework.liquibase.migrations-configmap-name` | `<fullname>-<name>-migrations` |
| `helm-framework.liquibase.env-secret-name` | `<fullname>-<name>-env` |
| `helm-framework.liquibase.url` | the composed JDBC URL |
| `helm-framework.liquibase.env` | the full `env:` list |

`_values.tpl` gains nothing for Liquibase. That file is the per-value defaults
layer, and with the engine enum removed there are no Liquibase defaults left to
host there — `helm-framework.liquibase.url` reads `database.url` /
`database.urlTemplate` directly.

## Refactor: shared Job partials

The new Job template is standalone rather than a synthetic `jobs[]` entry.
To avoid maintaining two divergent pod specs, the common parts of
`_job.yaml` are extracted into partials that both templates include:

| Partial | Covers |
|---|---|
| `helm-framework.job.podAnnotations` | appSettings / helmFrameworkSettings checksums plus `podAnnotations` |
| `helm-framework.job.podLabels` | `helm-framework.labels` plus `podLabels` |
| `helm-framework.job.caBundleInit` | the `ca-bundle-init` init container |
| `helm-framework.job.resources` | VPA-aware resources; takes `dict "root" $ "resources" $res` |
| `helm-framework.job.commonVolumes` | appSettings, cert-combine, scripts, authorities volumes |
| `helm-framework.job.commonVolumeMounts` | appSettings and ca-bundle mounts |
| `helm-framework.job.scheduling` | `nodeSelector`, `affinity`, `tolerations` |

`imagePullSecrets` is deliberately *not* extracted: it is four lines of pure
`with` + `toYaml` passthrough with no logic that can drift, so a partial would
add byte-identity risk to the refactor without reducing maintenance.

This refactor lands first and must be provably behaviour-preserving: the
`helm template` output of `helm/helm-framework-test-template` must diff empty
before and after. Only then is `_liquibase.tpl` written against the
partials.

The Liquibase Job's container is named `liquibase` rather than
`$root.Chart.Name` (which is what `_job.yaml` uses), because the image is not
the application image.

## Wait-for-job wiring

Two call sites currently iterate `.Values.jobs`:

- `helm-framework.waitFor.active` in `_helpers.tpl` — also returns `true`
  when `liquibase.enabled` and `liquibase.waitForIt`.
- the `$waitForJobs` list in `_deployment.yaml` — prepends
  `job/<fullname>-<liquibase.name>` under the same condition.

Everything downstream follows for free: `automountServiceAccountToken`
(`_deployment.yaml`), ServiceAccount auto-creation (`_serviceaccount.tpl`,
`_helpers.tpl`), and the `<fullname>-wait-for-jobs` Role and RoleBinding
(`_role.tpl`). No new RBAC code, and `initContainer.waitFor` (image,
timeout, command/args override) applies unchanged.

## Validation

Added to `helm-framework.values.validate` in `_values-validation.tpl`,
following that file's existing `fail (printf ...)` style. All only apply
when `liquibase.enabled`.

1. Neither `database.url` nor `database.urlTemplate` set — with no per-driver
   defaults, one of the two is always required.
2. Neither `changelog.file` nor `changelog.content` set — there is nothing to
   migrate from.
3. `database.urlTemplate` uses a placeholder whose value is unset. The message
   names which, since substitution would otherwise put empty strings into a
   syntactically valid but unusable URL.
4. `database.urlTemplate` is malformed — a printf verb, an unknown
   placeholder, or no placeholders at all. See "Why the placeholders are
   named, not positional" above for each case.
5. `database.existingSecret.name` set together with a non-empty
   `database.password` — ambiguous about which wins.
6. `changelog.file` set but `.Files.Get` returns empty — a typo'd path would
   otherwise ship a silently empty ConfigMap and a migration that does
   nothing.
7. `migrations.paths` non-empty but `.Files.Glob` matches zero files — same
   silent-success failure mode.
8. `liquibase.name` collides with the name of an enabled `jobs[]` entry —
   both would render the same Job name.

Not validated, documented instead: the 1 MiB ConfigMap size limit, and that
migration files must be valid UTF-8 text (the ConfigMap `data` field cannot
carry binary content).

## Testing

- `helm/helm-framework-test-template` gains a `liquibase:` block with
  `enabled: true`, plus fixtures `liquibase/changelog.xml` and
  `liquibase/migrations/001_init.sql`. The existing `lint.yaml` CI workflow
  (`helm lint` and `ct lint` over the test template) then covers the new
  templates with no workflow changes.
- The `_job.yaml` refactor is gated on a byte-identical `helm template` diff
  of the test template chart, captured before the refactor begins.
- `npm test` must pass. `scripts/generate-skill.mjs` enforces a values
  contract: every top-level key read by a template must be declared in
  `helm/helm-framework/values.yaml`, and vice versa. Adding `liquibase` to
  both sides satisfies it; `scripts/generate-skill.test.mjs` exercises the
  guard.

  Two consequences for sequencing. First, the guard is bidirectional, so the
  `liquibase:` declaration in `values.yaml` and the first template that reads
  `.Values.liquibase` must land in the *same* commit — either alone leaves
  `npm test` red. Second, the read-set is detected by the regex
  `/\.Values\.([A-Za-z0-9_]+)/`, so at least one template must spell it
  literally as `.Values.liquibase`; the framework's defensive
  `(.Values.liquibase).foo` form satisfies this, but a hypothetical
  `(.Values).liquibase` would not.
- Manual verification that the rendered Deployment's `wait-for-job` init
  container lists the Liquibase Job, and that hook weights order the
  ConfigMaps and Secret before the Job.

## Documentation

- A `LIQUIBASE` section in `helm/helm-framework/values.yaml`, following the
  file's existing convention of a live default block followed by a commented
  full reference.
  The chart's own `helm/helm-framework/README.md` is auto-generated from those
  `# --` comments by the `Docs` workflow (`losisin/helm-docs-github-action`),
  so it is never hand-edited. The root `README.md` has no per-template table —
  it points at the generated chart README — so no root README change is
  needed.
- Regenerated plugin skill via `node scripts/generate-skill.mjs --version
  <X.Y.Z>`, which rewrites
  `plugins/helm-framework/skills/helm-framework/resources/values-reference.md`
  and the migration skill's values contract.

## Migration path for the reference chart

`spark-customer-webhooks-agentcontainer` after this lands:

- `job:` becomes `liquibase:`; `job.database.connectionStringTemplate`
  becomes `liquibase.database.urlTemplate` (keeping its `encrypt=false;`
  explicitly).
- `initContainer.waitForEnabled` is deleted — `liquibase.waitForIt`
  defaults to true.
- `rolePodUpdater` is deleted — the framework provisions the wait RBAC.
- The changelog ConfigMap template, migrations ConfigMap template, and
  Liquibase env Secret template are deleted, along with the
  `liquibase-configmap-name`, `migration-configmap-name`, and
  `liquibase-env-secret-name` helpers, and the `volumes` / `volumeMounts`
  entries that wired them.
- The plaintext `database.password` should move to
  `database.existingSecret`, wired to the chart's existing ExternalSecret if
  it has one.

## Rejected alternatives

- **Synthetic `jobs[]` entry.** A helper composing a job dict from
  `liquibase` and prepending it to `.Values.jobs`, with `_job.yaml` and the
  wait logic iterating the helper's output. Maximum reuse and zero
  Liquibase awareness in the wait machinery, but the helper must round-trip
  through `fromYaml`, and the resulting indirection makes the Job template
  harder to read. Rejected in favour of a standalone template plus extracted
  partials, which reaches the same de-duplication more legibly.
- **Preset without ConfigMap generation.** Framework composes only the
  connection and the Job; the consuming chart keeps its own changelog and
  migrations ConfigMaps. Smaller surface, but leaves most of the reference
  chart's boilerplate in place.
- **Tool-neutral `dbMigration` abstraction.** Deferred until a second
  migration tool is actually needed.
- **Documentation-only recipe.** Every consuming chart would repeat the
  boilerplate.
