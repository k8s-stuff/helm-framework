{{- define "helm-framework.deployment.secret-scripts" -}}
{{- if ((.Values.initContainer).caBundle).enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.secret-scripts" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
data:
  combine-certs.sh: {{ (include "helm-framework.scripts.combine-certs" .) | replace "\r\n" "\n" | b64enc }}
{{- end }}
{{- end }}
