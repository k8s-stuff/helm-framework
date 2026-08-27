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
- Framework knowledge of per-engine JDBC option syntax. The framework
  composes a URL from a printf template and stops there.
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
    engine: sqlserver         # sqlserver | postgresql | mysql | oracle
    host: ""                  # required unless `url` is set
    port: 0                   # 0 selects the engine default
    name: ""                  # required unless `url` is set
    userName: ""
    password: ""
    urlTemplate: ""           # printf override; args are host, port, name
    url: ""                   # literal override, tpl-rendered; skips composition
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

### Engine defaults

| engine | default port | default urlTemplate |
|---|---|---|
| `sqlserver` | 1433 | `jdbc:sqlserver://%s:%s;database=%s;` |
| `postgresql` | 5432 | `jdbc:postgresql://%s:%s/%s` |
| `mysql` | 3306 | `jdbc:mysql://%s:%s/%s` |
| `oracle` | 1521 | `jdbc:oracle:thin:@%s:%s/%s` |

The `sqlserver` template deliberately omits `encrypt=false`. The MSSQL
driver's own default applies; a chart that needs transport encryption
relaxed sets `database.urlTemplate` explicitly, so the choice is visible in
that chart's values and in review rather than inherited invisibly. Charts
migrating from a hand-rolled `connectionStringTemplate` that carried
`encrypt=false;` must carry it over as `database.urlTemplate`.

Resolution order for the URL: `database.url` (tpl-rendered) wins outright;
otherwise `database.urlTemplate` or the engine default is filled via
`printf` with host, resolved port, and name.

### Composed environment

The Job container receives:

| Variable | Source |
|---|---|
| `LIQUIBASE_COMMAND_URL` | composed as above |
| `LIQUIBASE_COMMAND_USERNAME` | `database.userName`, or `secretKeyRef` when `existingSecret.name` is set |
| `LIQUIBASE_COMMAND_PASSWORD` | `database.password`, or `secretKeyRef` when `existingSecret.name` is set |
| `LIQUIBASE_LOG_LEVEL` | `log.level` |
| `LIQUIBASE_SEARCH_PATH` | `dir changelog.mountPath` (so `/liquibase` by default), making the default `--changeLogFile=changelog.xml` resolve against the mount even if `mountPath` is overridden |

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

The engine port and urlTemplate lookup tables live in `_values.tpl` as
`helm-framework.values.liquibase.port` and
`helm-framework.values.liquibase.urlTemplate`, following that file's
existing role as the defaults layer.

## Refactor: shared Job partials

The new Job template is standalone rather than a synthetic `jobs[]` entry.
To avoid maintaining two divergent pod specs, the common parts of
`_job.yaml` are extracted into partials that both templates include:

| Partial | Covers |
|---|---|
| `helm-framework.job.podAnnotations` | appSettings / helmFrameworkSettings checksums plus `podAnnotations` |
| `helm-framework.job.podLabels` | `helm-framework.labels` plus `podLabels` |
| `helm-framework.job.imagePullSecrets` | `imagePullSecrets` block |
| `helm-framework.job.caBundleInit` | the `ca-bundle-init` init container |
| `helm-framework.job.resources` | VPA-aware resources; takes `dict "root" $ "resources" $res` |
| `helm-framework.job.commonVolumes` | appSettings, cert-combine, scripts, authorities volumes |
| `helm-framework.job.commonVolumeMounts` | appSettings and ca-bundle mounts |
| `helm-framework.job.scheduling` | `nodeSelector`, `affinity`, `tolerations` |

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

1. Neither `database.url` nor both of `database.host` and `database.name`
   set.
2. Neither `changelog.file` nor `changelog.content` set — there is nothing to
   migrate from.
3. `database.engine` not in the supported set, when no `database.urlTemplate`
   or `database.url` is given. The message lists the supported engines.
   An unrecognised `engine` combined with an explicit `database.urlTemplate`
   is allowed — that is the escape hatch for an unsupported driver — but
   then `database.port` must be set explicitly, since there is no engine
   default to fall back on. Validate that too.
4. `database.existingSecret.name` set together with a non-empty
   `database.password` — ambiguous about which wins.
5. `changelog.file` set but `.Files.Get` returns empty — a typo'd path would
   otherwise ship a silently empty ConfigMap and a migration that does
   nothing.
6. `migrations.paths` non-empty but `.Files.Glob` matches zero files — same
   silent-success failure mode.
7. `liquibase.name` collides with the name of an enabled `jobs[]` entry —
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
- Manual verification that the rendered Deployment's `wait-for-job` init
  container lists the Liquibase Job, and that hook weights order the
  ConfigMaps and Secret before the Job.

## Documentation

- A `LIQUIBASE` section in `helm/helm-framework/values.yaml`, following the
  file's existing convention of a live default block followed by a commented
  full reference.
- A row in the root `README.md` template table.
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
