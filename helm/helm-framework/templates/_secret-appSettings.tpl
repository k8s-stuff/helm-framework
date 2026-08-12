{{- define "helm-framework.deployment.secret-app-settings" -}}
{{- if .Values.appSettings }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.secret-app-settings" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
  {{ include "helm-framework.values.configFileName" . }}: {{ (tpl (toYaml .Values.appSettings) .) | fromYaml | include "helm-framework.toPrettyJsonRaw" | b64enc }}
{{- end }}
{{- end }}
