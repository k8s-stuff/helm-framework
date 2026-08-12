{{- define "helm-framework.deployment.pdb" -}}
{{- $pdb := .Values.podDisruptionBudget | default dict -}}
{{- if $pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "helm-framework.fullname" . }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with $pdb.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $pdb.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $pdb.minAvailable }}
  minAvailable: {{ $pdb.minAvailable }}
  {{- else }}
  maxUnavailable: {{ $pdb.maxUnavailable | default 1 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "helm-framework.selectorLabels" . | nindent 6 }}
{{- end }}
{{- end }}
