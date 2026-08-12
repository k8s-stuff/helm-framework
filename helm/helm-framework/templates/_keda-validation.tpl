{{/*
KEDA Configuration Validation

This template provides validation for KEDA configuration to help catch
common configuration errors at template rendering time.
*/}}

{{- define "helm-framework.keda.validate" -}}
{{- if (.Values.keda).enabled }}

{{/* Validate that triggers are configured */}}
{{- if not (.Values.keda.scaledObject).triggers }}
{{- fail "KEDA is enabled but no triggers are configured in keda.scaledObject.triggers" }}
{{- end }}

{{/* Validate trigger authentication references */}}
{{- range .Values.keda.scaledObject.triggers }}
  {{- if .authenticationRef }}
    {{- if not $.Values.keda.triggerAuthentication }}
{{- fail "Trigger uses authenticationRef but no triggerAuthentication is configured" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Validate scaling parameters */}}
{{- if (.Values.keda.scaledObject).minReplicaCount }}
  {{- if (.Values.keda.scaledObject).maxReplicaCount }}
    {{- if gt (.Values.keda.scaledObject.minReplicaCount | int) (.Values.keda.scaledObject.maxReplicaCount | int) }}
{{- fail "keda.scaledObject.minReplicaCount cannot be greater than maxReplicaCount" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Validate idleReplicaCount */}}
{{- if hasKey .Values.keda.scaledObject "idleReplicaCount" }}
  {{- if (.Values.keda.scaledObject).minReplicaCount }}
    {{- if gt (.Values.keda.scaledObject.idleReplicaCount | int) (.Values.keda.scaledObject.minReplicaCount | int) }}
{{- fail "keda.scaledObject.idleReplicaCount cannot be greater than minReplicaCount" }}
    {{- end }}
  {{- end }}
{{- end }}

{{- end }}
{{- end }}
