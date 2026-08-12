{{- define "helm-framework.deployment.secret-sidecar-app-settings" -}}
{{- $state := dict "rendered" false -}}
{{- range $sc := .Values.sidecars }}
{{- if and $sc.enabled $sc.appSettings }}
{{- if $state.rendered }}
---
{{- end }}
{{- $_ := set $state "rendered" true }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.secret-sidecar-app-settings" (dict "root" $ "name" $sc.name) }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
  {{ include "helm-framework.values.configFileName" $ }}: {{ $sc.appSettings | default dict | include "helm-framework.toPrettyJsonRaw" | b64enc }}
{{- end }}
{{- end }}
{{- end }}
