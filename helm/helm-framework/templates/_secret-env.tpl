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

{{- define "helm-framework.deployment.secret-sidecar-env" -}}
{{- $state := dict "rendered" false -}}
{{- range $sc := .Values.sidecars }}
{{- if and $sc.enabled $sc.envVarsFromSecret }}
{{- if $state.rendered }}
---
{{- end }}
{{- $_ := set $state "rendered" true }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.secret-sidecar-env-name" (dict "root" $ "name" $sc.name) }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
  {{- range $key, $value := $sc.envVarsFromSecret }}
  {{$key}}: {{$value | toString | b64enc}}
  {{- end}}
{{- end }}
{{- end }}
{{- end }}
