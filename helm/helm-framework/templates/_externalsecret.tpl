{{- define "helm-framework.deployment.externalsecret" -}}
{{- $root := . -}}
{{- $state := dict "rendered" false -}}
{{- range $name, $config := .Values.externalSecrets }}
{{- if $state.rendered }}
---
{{- end }}
{{- $_ := set $state "rendered" true }}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ $name }}
  labels:
    {{- include "helm-framework.labels" $root | nindent 4 }}
  {{- with $config.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $config.refreshInterval }}
  refreshInterval: {{ $config.refreshInterval }}
  {{- end }}
  {{- if $config.secretStoreRef }}
  secretStoreRef:
    {{- toYaml $config.secretStoreRef | nindent 4 }}
  {{- end }}
  {{- if $config.target }}
  target:
    {{- toYaml $config.target | nindent 4 }}
  {{- end }}
  {{- if $config.data }}
  data:
    {{- toYaml $config.data | nindent 4 }}
  {{- end }}
  {{- if $config.dataFrom }}
  dataFrom:
    {{- toYaml $config.dataFrom | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
