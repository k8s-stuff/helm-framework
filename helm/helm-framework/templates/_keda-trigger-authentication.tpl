{{- define "helm-framework.keda.trigger-authentication" -}}
{{- $ta := (.Values.keda).triggerAuthentication | default dict -}}
{{- if and (.Values.keda).enabled (or $ta.secretTargetRef $ta.podIdentity $ta.env) }}
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: {{ $ta.name | default (printf "%s-trigger-auth" (include "helm-framework.fullname" .)) }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
spec:
  {{- if $ta.secretTargetRef }}
  secretTargetRef:
    {{- range $ta.secretTargetRef }}
    - parameter: {{ .parameter }}
      name: {{ .name }}
      key: {{ .key }}
    {{- end }}
  {{- end }}
  {{- if $ta.podIdentity }}
  podIdentity:
    provider: {{ $ta.podIdentity.provider }}
    {{- if $ta.podIdentity.identityId }}
    identityId: {{ $ta.podIdentity.identityId }}
    {{- end }}
  {{- end }}
  {{- if $ta.env }}
  env:
    {{- range $ta.env }}
    - parameter: {{ .parameter }}
      name: {{ .name }}
      {{- if .containerName }}
      containerName: {{ .containerName }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
