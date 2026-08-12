{{/*
Cross-cutting values validation for mechanisms not covered by
_keda-validation.tpl / _autoscaling-validation.tpl: sidecars, jobs, ingress,
virtualService, authorizationPolicy, and podDisruptionBudget.
*/}}

{{- define "helm-framework.values.validate" -}}
{{- $svcPort := (include "helm-framework.values.service.port" .) -}}
{{- $seenNames := dict -}}
{{- $seenPorts := dict (toString $svcPort) "service.port (main container)" -}}
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

{{- end -}}
