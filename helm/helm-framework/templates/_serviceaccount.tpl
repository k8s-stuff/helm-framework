{{- define "helm-framework.deployment.serviceAccount" -}}
{{- if or ((.Values.serviceAccount).create) (and (include "helm-framework.waitFor.active" .) (not (.Values.serviceAccount).name)) -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "helm-framework.serviceAccountName" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with (.Values.serviceAccount).annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- /* Sprig's `default` treats boolean false as empty, so `automount | default true` would always render true — hasKey avoids that. */}}
automountServiceAccountToken: {{ if hasKey (.Values.serviceAccount | default dict) "automount" }}{{ .Values.serviceAccount.automount }}{{ else }}true{{ end }}
{{- end }}
{{- end }}
