{{/*
ConfigMaps holding the Liquibase changelog and migration SQL. Both are
pre-install/pre-upgrade hooks at weight -20, below the migration Job at -10,
so they exist before the Job pod starts.

Content comes from the CONSUMING chart's files: the chart that includes
helm-framework.deployment.global passes its own root context, so `.Files`
resolves against that chart's directory, not the library's. Inline
`changelog.content` / `migrations.files` are the fallback for charts that
would rather keep everything in values.yaml.
*/}}
{{- define "helm-framework.deployment.liquibase-configmaps" -}}
{{- if (.Values.liquibase).enabled -}}
{{- $changelog := "" -}}
{{- with ((.Values.liquibase).changelog).file -}}
{{- $changelog = $.Files.Get . -}}
{{- end -}}
{{- if not $changelog -}}
{{- $changelog = (((.Values.liquibase).changelog).content | default "") -}}
{{- end -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "helm-framework.liquibase.changelog-configmap-name" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
data:
  {{ include "helm-framework.liquibase.changelog-key" . }}: |
{{ $changelog | trim | indent 4 }}
{{- if eq (include "helm-framework.liquibase.has-migrations" .) "true" }}
{{- $migrations := dict -}}
{{- range $name, $content := ((.Values.liquibase).migrations).files -}}
{{- $_ := set $migrations $name (toString $content) -}}
{{- end -}}
{{- range $pattern := ((.Values.liquibase).migrations).paths -}}
{{- range $path, $bytes := $.Files.Glob $pattern -}}
{{- $_ := set $migrations (base $path) (toString $bytes) -}}
{{- end -}}
{{- end }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "helm-framework.liquibase.migrations-configmap-name" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
data:
  {{- range $name, $content := $migrations }}
  {{ $name }}: |
{{ $content | trim | indent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
