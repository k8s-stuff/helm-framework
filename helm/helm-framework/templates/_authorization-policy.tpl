{{- define "helm-framework.deployment.authorizationPolicy" -}}
{{- $root := . -}}
{{- $state := dict "rendered" false -}}
{{- range $index, $ap := .Values.authorizationPolicy }}
{{- if $ap.enabled }}
{{- if $state.rendered }}
---
{{- end }}
{{- $_ := set $state "rendered" true }}
{{- $name := $ap.name | default (printf "authz-%d" $index) }}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ include "helm-framework.fullname" $root }}-{{ $name }}
  labels:
    {{- include "helm-framework.labels" $root | nindent 4 }}
    {{- with $ap.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $ap.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $ap.selector }}
  selector:
    {{- toYaml $ap.selector | nindent 4 }}
  {{- else if not $ap.targetRefs }}
  selector:
    matchLabels:
      {{- include "helm-framework.selectorLabels" $root | nindent 6 }}
  {{- end }}
  {{- with $ap.targetRefs }}
  targetRefs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  action: {{ $ap.action | default "ALLOW" }}
  {{- if and (eq ($ap.action | default "ALLOW") "CUSTOM") $ap.provider }}
  provider:
    {{- toYaml $ap.provider | nindent 4 }}
  {{- end }}
  {{- with $ap.rules }}
  rules:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
