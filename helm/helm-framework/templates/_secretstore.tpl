{{- define "helm-framework.deployment.secretstore" -}}
{{- if .Values.secretStore }}
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: {{ include "helm-framework.fullname" . }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
  {{- with .Values.secretStore.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- toYaml .Values.secretStore.spec | nindent 2 }}
{{- end }}
{{- end }}
