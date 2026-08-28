{{/*
The Liquibase database credentials Secret. A pre-install/pre-upgrade hook at
weight -20, below the migration Job at -10, so it exists before the Job pod
starts.

Skipped entirely when database.existingSecret.name is set — that is the
supported path for production credentials (point it at an ExternalSecret)
instead of putting a password in values.yaml. Holds only the username and
password; the JDBC URL is a plain env var on the Job container.
*/}}
{{- define "helm-framework.deployment.liquibase-secret" -}}
{{- if (.Values.liquibase).enabled -}}
{{- $db := ((.Values.liquibase).database | default dict) -}}
{{- if not ($db.existingSecret | default dict).name -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "helm-framework.liquibase.env-secret-name" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
data:
  LIQUIBASE_COMMAND_USERNAME: {{ $db.userName | default "" | toString | b64enc | quote }}
  LIQUIBASE_COMMAND_PASSWORD: {{ $db.password | default "" | toString | b64enc | quote }}
{{- end }}
{{- end }}
{{- end }}
