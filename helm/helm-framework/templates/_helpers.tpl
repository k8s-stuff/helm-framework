{{/*
Expand the name of the chart.
*/}}
{{- define "helm-framework.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-framework.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-framework.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm-framework.labels" -}}
helm.sh/chart: {{ include "helm-framework.chart" . }}
{{ include "helm-framework.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- /* Legacy bare `app` label kept only because helm-framework.values.affinity's podAntiAffinity selector matches on it. */}}
app: {{ include "helm-framework.name" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-framework.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-framework.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm-framework.serviceAccountName" -}}
{{- if (.Values.serviceAccount).name }}
{{- (.Values.serviceAccount).name }}
{{- else if or ((.Values.serviceAccount).create) (include "helm-framework.waitFor.active" .) }}
{{- include "helm-framework.fullname" . }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}

{{- define "helm-framework.rbac.roleName" -}}
{{- (.Values.rbac).roleName | default (printf "%s-role" (include "helm-framework.fullname" .)) }}
{{- end -}}

{{/*
Returns "true" when at least one enabled job is flagged with waitForIt.
Used to auto-provision RBAC so the wait-for-job init container can read jobs.
*/}}
{{- define "helm-framework.waitFor.active" -}}
{{- $active := false -}}
{{- range $index, $job := .Values.jobs -}}
{{- if and $job.enabled $job.waitForIt -}}
{{- $active = true -}}
{{- end -}}
{{- end -}}
{{- if $active }}true{{- end -}}
{{- end -}}

{{- define "helm-framework.secret-env-name" -}}
{{- include "helm-framework.fullname" . }}-secret-env
{{- end }}

{{- define "helm-framework.secret-app-settings" -}}
{{- include "helm-framework.fullname" . }}-app-settings
{{- end }}

{{/*
Secret name for a sidecar's appSettings. Expects a dict: { root, name }.
*/}}
{{- define "helm-framework.secret-sidecar-app-settings" -}}
{{- printf "%s-%s-app-settings" (include "helm-framework.fullname" .root) .name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Secret name for a sidecar's envVarsFromSecret. Expects a dict: { root, name }.
*/}}
{{- define "helm-framework.secret-sidecar-env-name" -}}
{{- printf "%s-%s-secret-env" (include "helm-framework.fullname" .root) .name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Plain `env` list for a sidecar container: the release-wide envVars, minus every name
the sidecar redefines, followed by the sidecar's own envVars. Names the sidecar
sources from its own Secret are dropped from the list too — a container's `env`
always beats `envFrom`, so a release-wide entry left in place would shadow the
sidecar's Secret value. Expects a dict: { root, sidecar }.
Renders nothing when the sidecar ends up with no plain env vars at all.
*/}}
{{- define "helm-framework.sidecar.env" -}}
{{- $sc := .sidecar -}}
{{- $overridden := dict -}}
{{- range $sc.envVars -}}
{{- $_ := set $overridden .name true -}}
{{- end -}}
{{- range $key, $value := ($sc.envVarsFromSecret | default dict) -}}
{{- $_ := set $overridden $key true -}}
{{- end -}}
{{- $env := list -}}
{{- range .root.Values.envVars -}}
{{- if not (hasKey $overridden .name) -}}
{{- $env = append $env . -}}
{{- end -}}
{{- end -}}
{{- range $sc.envVars -}}
{{- $env = append $env . -}}
{{- end -}}
{{- if $env -}}
{{- toYaml $env -}}
{{- end -}}
{{- end }}

{{/*
Container/Service port name for a sidecar. Expects the sidecar entry (uses .name).
Port names are limited to 15 chars, so the sidecar name must stay short and unique.
*/}}
{{- define "helm-framework.sidecar.portName" -}}
{{- printf "sc-%s" .name | trunc 15 | trimSuffix "-" -}}
{{- end }}

{{- define "helm-framework.secret-scripts" -}}
{{- include "helm-framework.fullname" . }}-secret-scripts
{{- end }}

{{- define "helm-framework.secret-authorities" -}}
{{- include "helm-framework.fullname" . }}-secret-authorities
{{- end }}

{{- define "helm-framework.secret-tls" -}}
{{- include "helm-framework.fullname" . }}-tls
{{- end }}

{{- define "helm-framework.is-flag-enabled-default-true" -}}
{{- if and . (hasKey . "enabled") -}}
{{- .enabled -}}
{{- else -}}
{{- printf "true" }}
{{- end -}}
{{- end -}}

{{/*
Container probes (startup/liveness/readiness).
Expects a dict: { healthChecks, portName, scheme }.
Renders nothing when healthChecks.enabled is explicitly false (default: enabled).
*/}}
{{- define "helm-framework.probes" -}}
{{- $hc := .healthChecks -}}
{{- $port := .portName -}}
{{- $scheme := .scheme -}}
{{- if eq (include "helm-framework.is-flag-enabled-default-true" $hc) "true" -}}
startupProbe:
  httpGet:
    path: {{ (($hc).startupProbe).path | default "/health/startup" }}
    port: {{ $port }}
    scheme: {{ $scheme }}
  periodSeconds: {{ (($hc).startupProbe).periodSeconds | default 5 }}
  failureThreshold: {{ (($hc).startupProbe).failureThreshold | default 30 }}
  successThreshold: {{ (($hc).startupProbe).successThreshold | default 1 }}
  initialDelaySeconds: {{ dig "initialDelaySeconds" 10 (($hc).startupProbe | default dict) }}
  timeoutSeconds: {{ (($hc).startupProbe).timeoutSeconds | default 3 }}
livenessProbe:
  httpGet:
    path: {{ (($hc).livenessProbe).path | default "/health/liveness" }}
    port: {{ $port }}
    scheme: {{ $scheme }}
  periodSeconds: {{ (($hc).livenessProbe).periodSeconds | default 10 }}
  failureThreshold: {{ (($hc).livenessProbe).failureThreshold | default 10 }}
  successThreshold: {{ (($hc).livenessProbe).successThreshold | default 1 }}
  initialDelaySeconds: {{ dig "initialDelaySeconds" 1 (($hc).livenessProbe | default dict) }}
  timeoutSeconds: {{ (($hc).livenessProbe).timeoutSeconds | default 3 }}
readinessProbe:
  httpGet:
    path: {{ (($hc).readinessProbe).path | default "/health/readiness" }}
    port: {{ $port }}
    scheme: {{ $scheme }}
  periodSeconds: {{ (($hc).readinessProbe).periodSeconds | default 10 }}
  failureThreshold: {{ (($hc).readinessProbe).failureThreshold | default 3 }}
  successThreshold: {{ (($hc).readinessProbe).successThreshold | default 1 }}
  initialDelaySeconds: {{ dig "initialDelaySeconds" 1 (($hc).readinessProbe | default dict) }}
  timeoutSeconds: {{ (($hc).readinessProbe).timeoutSeconds | default 3 }}
{{- end }}
{{- end }}

{{/*
KEDA helper functions
*/}}
{{- define "helm-framework.keda.trigger-auth-name" -}}
{{- .Values.keda.triggerAuthentication.name | default (printf "%s-trigger-auth" (include "helm-framework.fullname" .)) }}
{{- end }}

{{- define "helm-framework.keda.scaled-object-name" -}}
{{- include "helm-framework.fullname" . }}-scaledobject
{{- end }}

{{/*
Convert to pretty JSON without HTML-escaping special URL characters.
Helm's toPrettyJson uses Go's encoding/json which escapes &, <, > for HTML safety.
*/}}
{{- define "helm-framework.toPrettyJsonRaw" -}}
{{- . | toPrettyJson | replace "\\u0026" "&" | replace "\\u003c" "<" | replace "\\u003e" ">" -}}
{{- end -}}

{{/*
No security-context defaults are forced here. Any hardened baseline
(runAsNonRoot, readOnlyRootFilesystem, allowPrivilegeEscalation, dropped
capabilities, seccompProfile, ...) requires knowing the target image's user
and platform (vanilla Kubernetes vs. OpenShift's per-namespace SCC UID
ranges), which this chart can't assume for every consumer/image. These
helpers just pass through whatever the consumer sets in
podSecurityContext/securityContext, rendering `{}` when nothing is set, so
the chart works out of the box on vanilla Kubernetes and OpenShift alike.
Consumers that want a hardened posture set the fields themselves, e.g.
`securityContext: { runAsNonRoot: true, runAsUser: 1000, readOnlyRootFilesystem: true }`.
*/}}
{{- define "helm-framework.podSecurityContext" -}}
{{- (. | default dict) | toYaml -}}
{{- end -}}

{{- define "helm-framework.securityContext" -}}
{{- (. | default dict) | toYaml -}}
{{- end -}}

{{- define "helm-framework.keda.is-enabled" -}}
{{- if and (.Values.keda) (.Values.keda.enabled) -}}
{{- printf "true" }}
{{- else -}}
{{- printf "false" }}
{{- end -}}
{{- end -}}

{{/*
Liquibase resource names. Everything derives from
<fullname>-<liquibase.name> so the Job, its ConfigMaps, and its Secret stay
grouped and predictable.
*/}}
{{- define "helm-framework.liquibase.name" -}}
{{- (.Values.liquibase).name | default "liquibase" }}
{{- end }}

{{- define "helm-framework.liquibase.job-name" -}}
{{- include "helm-framework.fullname" . }}-{{ include "helm-framework.liquibase.name" . }}
{{- end }}

{{- define "helm-framework.liquibase.changelog-configmap-name" -}}
{{- include "helm-framework.liquibase.job-name" . }}-changelog
{{- end }}

{{- define "helm-framework.liquibase.migrations-configmap-name" -}}
{{- include "helm-framework.liquibase.job-name" . }}-migrations
{{- end }}

{{- define "helm-framework.liquibase.env-secret-name" -}}
{{- include "helm-framework.liquibase.job-name" . }}-env
{{- end }}

{{/*
The changelog's ConfigMap key, which is also the volume subPath. Derived from
changelog.mountPath's basename so the ConfigMap, the mount, and
LIQUIBASE_SEARCH_PATH can never disagree.
*/}}
{{- define "helm-framework.liquibase.changelog-key" -}}
{{- base (((.Values.liquibase).changelog).mountPath | default "/liquibase/changelog.xml") }}
{{- end }}

{{/*
Returns "true" when at least one migration file resolves, from either
migrations.paths globs or the inline migrations.files map. Used to decide
whether the migrations ConfigMap, volume, and mount are rendered at all — a
self-contained changelog needs none of them.
*/}}
{{- define "helm-framework.liquibase.has-migrations" -}}
{{- $found := false -}}
{{- if ((.Values.liquibase).migrations).files -}}
{{- $found = true -}}
{{- end -}}
{{- range $pattern := ((.Values.liquibase).migrations).paths -}}
{{- if $.Files.Glob $pattern -}}
{{- $found = true -}}
{{- end -}}
{{- end -}}
{{- if $found }}true{{- end -}}
{{- end }}

{{/*
The composed JDBC URL. `database.url` wins outright and is tpl-rendered so it
can reference other values; otherwise the engine (or overridden) printf
template is filled with host, resolved port, and database name.
*/}}
{{- define "helm-framework.liquibase.url" -}}
{{- $db := ((.Values.liquibase).database | default dict) -}}
{{- if $db.url -}}
{{- tpl $db.url . -}}
{{- else -}}
{{- printf (include "helm-framework.values.liquibase.urlTemplate" .) ($db.host | toString) (include "helm-framework.values.liquibase.port" .) ($db.name | toString) -}}
{{- end -}}
{{- end }}

{{/*
The Liquibase Job container's env list, at relative indent 0.

The URL is a plain value: a connection target is not a credential, and keeping
it in the pod spec makes `kubectl describe job` diagnostic. Only the username
and password are Secret-sourced — from the generated Secret, or from
database.existingSecret when that is set.

LIQUIBASE_SEARCH_PATH is the changelog mount's directory, so the default
`--changeLogFile=changelog.xml` keeps resolving even if mountPath is changed.
*/}}
{{- define "helm-framework.liquibase.env" -}}
{{- $db := ((.Values.liquibase).database | default dict) -}}
{{- $existing := ($db.existingSecret | default dict) -}}
{{- $changelogMount := (((.Values.liquibase).changelog).mountPath | default "/liquibase/changelog.xml") -}}
- name: LIQUIBASE_COMMAND_URL
  value: {{ include "helm-framework.liquibase.url" . | quote }}
{{- if $existing.name }}
- name: LIQUIBASE_COMMAND_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ tpl $existing.name . | quote }}
      key: {{ $existing.usernameKey | default "username" | quote }}
- name: LIQUIBASE_COMMAND_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ tpl $existing.name . | quote }}
      key: {{ $existing.passwordKey | default "password" | quote }}
{{- else }}
- name: LIQUIBASE_COMMAND_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "helm-framework.liquibase.env-secret-name" . | quote }}
      key: LIQUIBASE_COMMAND_USERNAME
- name: LIQUIBASE_COMMAND_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "helm-framework.liquibase.env-secret-name" . | quote }}
      key: LIQUIBASE_COMMAND_PASSWORD
{{- end }}
- name: LIQUIBASE_LOG_LEVEL
  value: {{ (((.Values.liquibase).log).level | default "INFO") | quote }}
- name: LIQUIBASE_SEARCH_PATH
  value: {{ dir $changelogMount | quote }}
{{- with (.Values.liquibase).extraEnvVars }}
{{ tpl (toYaml .) $ | trim }}
{{- end }}
{{- end }}
