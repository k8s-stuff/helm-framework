{{/*
Cross-cutting values validation for mechanisms not covered by
_keda-validation.tpl / _autoscaling-validation.tpl: Service ports (main,
service.extraPorts, sidecars), extraServices, sidecars, jobs, ingress,
virtualService, authorizationPolicy, and podDisruptionBudget.
*/}}

{{- define "helm-framework.values.validate" -}}
{{- $svcPort := (include "helm-framework.values.service.port" .) -}}
{{- $seenNames := dict -}}
{{- $seenPorts := dict (toString $svcPort) "service.port (main container)" -}}
{{- $seenPortNames := dict "http" "the main container's Service port" -}}
{{- range $index, $p := (.Values.service).extraPorts }}
  {{- if not $p.name }}
{{- fail (printf "service.extraPorts[%d] has no name: every entry must be named, since adding one makes the Service expose more than one port." $index) }}
  {{- end }}
  {{- if not $p.port }}
{{- fail (printf "service.extraPorts[%d] (%s) has no port: set the port the Service should expose." $index $p.name) }}
  {{- end }}
  {{- if hasKey $seenPortNames $p.name }}
{{- fail (printf "service.extraPorts[%d]'s name %q collides with %s: each port exposed on the chart's Service must have a unique name." $index $p.name (get $seenPortNames $p.name)) }}
  {{- end }}
  {{- $_ := set $seenPortNames $p.name (printf "service.extraPorts %q" $p.name) -}}
  {{- $port := toString $p.port -}}
  {{- if hasKey $seenPorts $port }}
{{- fail (printf "service.extraPorts[%d] (%s) port %s collides with %s: each port exposed on the chart's Service must be unique." $index $p.name $port (get $seenPorts $port)) }}
  {{- end }}
  {{- $_ := set $seenPorts $port (printf "service.extraPorts %q" $p.name) -}}
{{- end }}
{{- range .Values.sidecars }}
{{- if .enabled }}
  {{- $name := .name -}}
  {{- if hasKey $seenNames $name }}
{{- fail (printf "Duplicate sidecar name %q: sidecar names must be unique (used to derive the container, port, and Secret names)." $name) }}
  {{- end }}
  {{- $_ := set $seenNames $name true -}}
  {{- $port := toString (include "helm-framework.values.service.port" .) -}}
  {{- if hasKey $seenPorts $port }}
{{- fail (printf "Sidecar %q's service.port %s collides with %s: each port exposed on the chart's Service must be unique." $name $port (get $seenPorts $port)) }}
  {{- end }}
  {{- $_ := set $seenPorts $port (printf "sidecar %q" $name) -}}
  {{- $portName := include "helm-framework.sidecar.portName" . -}}
  {{- if hasKey $seenPortNames $portName }}
{{- fail (printf "Sidecar %q's derived Service port name %q collides with %s: each port exposed on the chart's Service must have a unique name (sidecar port names are \"sc-<name>\" truncated to 15 characters)." $name $portName (get $seenPortNames $portName)) }}
  {{- end }}
  {{- $_ := set $seenPortNames $portName (printf "sidecar %q" $name) -}}
{{- end }}
{{- end }}

{{- $seenExtraServiceNames := dict -}}
{{- range $index, $svc := .Values.extraServices }}
{{- if $svc.enabled }}
  {{- $svcName := $svc.name -}}
  {{- if not $svcName }}
{{- fail (printf "extraServices[%d] has no name: extraServices entries require a name (used to derive the Service resource name \"<fullname>-<name>\")." $index) }}
  {{- end }}
  {{- if hasKey $seenExtraServiceNames $svcName }}
{{- fail (printf "Duplicate extraServices name %q: extraServices names must be unique (used to derive the Service resource name)." $svcName) }}
  {{- end }}
  {{- $_ := set $seenExtraServiceNames $svcName true -}}
  {{- if and (($svc.sessionAffinityConfig).clientIPTimeoutSeconds) (ne ($svc.sessionAffinity | default "") "ClientIP") }}
{{- fail (printf "extraServices[%d] (%s): sessionAffinityConfig.clientIPTimeoutSeconds is set but sessionAffinity is not \"ClientIP\": the timeout has no effect without ClientIP affinity." $index $svcName) }}
  {{- end }}
  {{- $seenSvcPorts := dict -}}
  {{- $seenSvcPortNames := dict -}}
  {{- $multiPort := gt (len ($svc.ports | default list)) 1 -}}
  {{- range $portIndex, $p := $svc.ports }}
    {{- if not $p.port }}
{{- fail (printf "extraServices[%d] (%s) ports[%d] has no port: set the port the Service should expose." $index $svcName $portIndex) }}
    {{- end }}
    {{- if and $multiPort (not $p.name) }}
{{- fail (printf "extraServices[%d] (%s) ports[%d] has no name: a Service exposing more than one port must name every port." $index $svcName $portIndex) }}
    {{- end }}
    {{- with $p.name }}
    {{- if hasKey $seenSvcPortNames . }}
{{- fail (printf "extraServices[%d] (%s) ports[%d]: duplicate port name %q — port names must be unique within a Service." $index $svcName $portIndex .) }}
    {{- end }}
    {{- $_ := set $seenSvcPortNames . true -}}
    {{- end }}
    {{- $port := toString $p.port -}}
    {{- if hasKey $seenSvcPorts $port }}
{{- fail (printf "extraServices[%d] (%s) ports[%d]: duplicate port %s — ports must be unique within a Service." $index $svcName $portIndex $port) }}
    {{- end }}
    {{- $_ := set $seenSvcPorts $port true -}}
  {{- end }}
{{- end }}
{{- end }}

{{- $seenJobNames := dict -}}
{{- range $index, $job := .Values.jobs }}
{{- if $job.enabled }}
  {{- $jobName := $job.name | default (printf "job-%d" $index) -}}
  {{- if hasKey $seenJobNames $jobName }}
{{- fail (printf "Duplicate job name %q: job names must be unique (used to derive the Job resource name)." $jobName) }}
  {{- end }}
  {{- $_ := set $seenJobNames $jobName true -}}
{{- end }}
{{- end }}

{{- if (.Values.ingress).enabled }}
{{- if not .Values.ingress.hosts }}
{{- fail "ingress.enabled is true but ingress.hosts is empty: this would render an Ingress with no rules." }}
{{- end }}
{{- end }}

{{- if (.Values.virtualService).enabled }}
{{- if not (or .Values.virtualService.http .Values.virtualService.paths) }}
{{- fail "virtualService.enabled is true but neither virtualService.paths nor virtualService.http is set: this would render a VirtualService with no routes." }}
{{- end }}
{{- end }}

{{- $seenApNames := dict -}}
{{- range $index, $ap := .Values.authorizationPolicy }}
{{- if $ap.enabled }}
  {{- $apName := $ap.name | default (printf "authz-%d" $index) -}}
  {{- if hasKey $seenApNames $apName }}
{{- fail (printf "Duplicate authorizationPolicy name %q: authorizationPolicy names must be unique (used to derive the AuthorizationPolicy resource name)." $apName) }}
  {{- end }}
  {{- $_ := set $seenApNames $apName true -}}
  {{- if and (eq ($ap.action | default "ALLOW") "CUSTOM") (not $ap.provider) }}
{{- fail (printf "authorizationPolicy[%d] (%s): action CUSTOM requires provider.name — Istio rejects a CUSTOM AuthorizationPolicy without one." $index $apName) }}
  {{- end }}
{{- end }}
{{- end }}

{{- if and (((.Values.service).sessionAffinityConfig).clientIPTimeoutSeconds) (ne ((.Values.service).sessionAffinity) "ClientIP") }}
{{- fail "service.sessionAffinityConfig.clientIPTimeoutSeconds is set but service.sessionAffinity is not \"ClientIP\": the timeout has no effect without ClientIP affinity." }}
{{- end }}

{{- if (.Values.podDisruptionBudget).enabled }}
{{- if and .Values.podDisruptionBudget.minAvailable .Values.podDisruptionBudget.maxUnavailable }}
{{- fail "podDisruptionBudget.minAvailable and podDisruptionBudget.maxUnavailable are both set: only one may be used, and the chart silently renders minAvailable and drops maxUnavailable. Unset one." }}
{{- end }}
{{- end }}

{{- if (.Values.liquibase).enabled }}
{{- $lb := .Values.liquibase -}}
{{- $db := ($lb.database | default dict) -}}
{{- $existing := ($db.existingSecret | default dict) -}}
{{- $engines := list "sqlserver" "postgresql" "mysql" "oracle" -}}
{{- $customUrl := or $db.url $db.urlTemplate -}}
  {{- if and (not $db.url) (or (not $db.host) (not $db.name)) }}
{{- fail "liquibase.enabled is true but the database is not addressable: set liquibase.database.host and liquibase.database.name, or set liquibase.database.url to a literal JDBC URL." }}
  {{- end }}
  {{- if and (not ($lb.changelog | default dict).file) (not ($lb.changelog | default dict).content) }}
{{- fail "liquibase.enabled is true but no changelog is configured: set liquibase.changelog.file to a path inside your chart (e.g. \"liquibase/changelog.xml\"), or liquibase.changelog.content to an inline changelog." }}
  {{- end }}
  {{- if and (not $customUrl) (not (has ($db.engine | default "sqlserver") $engines)) }}
{{- fail (printf "liquibase.database.engine %q is not one of %s: pick a supported engine, or set liquibase.database.urlTemplate (and liquibase.database.port) to drive an unsupported driver yourself." ($db.engine | default "sqlserver") (join ", " $engines)) }}
  {{- end }}
  {{- if and (not (has ($db.engine | default "sqlserver") $engines)) (not $db.url) (not $db.port) }}
{{- fail (printf "liquibase.database.engine %q is unrecognised and liquibase.database.port is unset: there is no engine default to fall back on, so set the port explicitly." ($db.engine | default "sqlserver")) }}
  {{- end }}
  {{- if and $existing.name $db.password }}
{{- fail "liquibase.database.existingSecret.name and liquibase.database.password are both set: it is ambiguous which credential wins. Unset password to source it from the existing Secret, or unset existingSecret.name to use the generated one." }}
  {{- end }}
  {{- with ($lb.changelog | default dict).file }}
    {{- if not ($.Files.Get .) }}
{{- fail (printf "liquibase.changelog.file %q resolves to nothing in this chart: .Files.Get returned empty, which would ship an empty changelog ConfigMap and a migration that silently does nothing. Check the path is relative to your chart root and that the file is not excluded by .helmignore." .) }}
    {{- end }}
  {{- end }}
  {{- range $pattern := ($lb.migrations | default dict).paths }}
    {{- if not ($.Files.Glob $pattern) }}
{{- fail (printf "liquibase.migrations.paths pattern %q matches no files in this chart: this would ship an empty migrations ConfigMap. Check the glob is relative to your chart root and that the files are not excluded by .helmignore." $pattern) }}
    {{- end }}
  {{- end }}
  {{- $lbName := include "helm-framework.liquibase.name" . -}}
  {{- range $index, $job := .Values.jobs }}
    {{- if $job.enabled }}
      {{- if eq ($job.name | default (printf "job-%d" $index)) $lbName }}
{{- fail (printf "jobs[%d]'s name %q collides with liquibase.name: both would render a Job named \"<fullname>-%s\". Rename one of them." $index $lbName $lbName) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- end -}}
