{{/*
Cross-validation between the chart's autoscaling mechanisms (HPA, VPA, KEDA),
which can each be enabled independently but conflict when combined carelessly.
*/}}

{{- define "helm-framework.autoscaling.validate" -}}
{{- $hpa := .Values.horizontalPodAutoscaler | default dict -}}
{{- $vpa := .Values.verticalPodAutoscaler | default dict -}}
{{- $keda := .Values.keda | default dict -}}

{{- if and $hpa.enabled $keda.enabled }}
{{- fail "horizontalPodAutoscaler.enabled and keda.enabled cannot both be true: KEDA creates its own managed HorizontalPodAutoscaler for the same target, and two HPAs controlling one Deployment's replica count fight each other. Disable one." }}
{{- end }}

{{/* Utilization-based HPA metrics require the corresponding resource requests, otherwise metrics-server reports <unknown> and the HPA never scales. */}}
{{- if $hpa.enabled }}
  {{- if or $hpa.targetCPUUtilizationPercentage $hpa.targetMemoryUtilizationPercentage }}
    {{- if not (.Values.resources).requests }}
{{- fail "horizontalPodAutoscaler.targetCPUUtilizationPercentage/targetMemoryUtilizationPercentage require resources.requests.cpu/memory to be set, otherwise metrics-server cannot compute utilization and the HPA never scales." }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Per-container VPA minAllowed must not exceed maxAllowed for the same resource, otherwise VPA's admission
webhook rejects the resourcePolicy outright. Comparison is skipped when minAllowed/maxAllowed use different unit
suffixes (e.g. "2Gi" vs "512Mi") since Helm templates have no reliable way to normalize Kubernetes quantity units. */}}
{{- if $vpa.enabled }}
  {{- $policies := $vpa.containerPolicies | default (list ($vpa.defaultContainerPolicy | default dict)) }}
  {{- range $policy := $policies }}
    {{- $containerName := $policy.containerName | default "*" -}}
    {{- $minAllowed := $policy.minAllowed | default dict -}}
    {{- $maxAllowed := $policy.maxAllowed | default dict -}}
    {{- range $resource, $minVal := $minAllowed }}
      {{- if hasKey $maxAllowed $resource }}
        {{- include "helm-framework.vpa.checkBounds" (dict "container" $containerName "resource" $resource "min" $minVal "max" (get $maxAllowed $resource)) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- end }}

{{/*
Compares a single VPA minAllowed/maxAllowed pair for one resource key and fails if min > max. Skips the
comparison (renders nothing) when the two values don't share the same trailing unit suffix, to avoid a false
failure from comparing e.g. "2Gi" against "512Mi" without normalizing units. Expects a dict:
{ container, resource, min, max }.
*/}}
{{- define "helm-framework.vpa.checkBounds" -}}
{{- $minStr := toString .min -}}
{{- $maxStr := toString .max -}}
{{- $minNum := regexReplaceAll "[^0-9.]+$" $minStr "" -}}
{{- $minSuf := trimPrefix $minNum $minStr -}}
{{- $maxNum := regexReplaceAll "[^0-9.]+$" $maxStr "" -}}
{{- $maxSuf := trimPrefix $maxNum $maxStr -}}
{{- if and (eq $minSuf $maxSuf) (ne $minNum "") (ne $maxNum "") }}
  {{- if gt (float64 $minNum) (float64 $maxNum) }}
{{- fail (printf "verticalPodAutoscaler container policy %q: minAllowed.%s (%s) is greater than maxAllowed.%s (%s) — VPA rejects a resourcePolicy where the minimum exceeds the maximum." .container .resource $minStr .resource $maxStr) }}
  {{- end }}
{{- end }}
{{- end -}}
