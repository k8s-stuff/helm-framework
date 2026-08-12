{{- define "helm-framework.deployment.secret-authorities" -}}
{{- if ((.Values.initContainer).caBundle).enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.secret-authorities" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
{{- range $key, $value:= (required "List of trusted certification authorities is required!" ((.Values.initContainer).caBundle).trustedCertificateAuthorities) }}
  {{$key}}: {{$value}}
{{- end }}
{{- end }}
{{- end }}
