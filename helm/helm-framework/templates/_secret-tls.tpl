{{- define "helm-framework.deployment.secret-tls" -}}
{{- if (.Values.tls).enabled }}
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: {{ include "helm-framework.secret-tls" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
  tls.crt: {{ required "Certificate content is required once it is enabled!" .Values.tls.certFile }}
  tls.key: {{ required "Certificate key content is required once it is enabled!" .Values.tls.keyFile }}
{{- end }}
{{- end }}
