{{- define "helm-framework.deployment.secret-env" -}}
{{- if .Values.envVarsFromSecret }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.secret-env-name" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
  {{- range $key, $value := .Values.envVarsFromSecret }}
  {{$key}}: {{$value | toString | b64enc}}
  {{- end}}
{{- end }}
{{- end }}
