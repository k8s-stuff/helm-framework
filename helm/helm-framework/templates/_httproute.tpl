{{- define "helm-framework.deployment.httproute" -}}
{{- $hr := .Values.httpRoute | default dict -}}
{{- $fullName := include "helm-framework.fullname" . -}}
{{- $svcPort := (include "helm-framework.values.service.port" .) -}}
{{- if $hr.enabled -}}
apiVersion: {{ $hr.apiVersion | default "gateway.networking.k8s.io/v1" }}
kind: HTTPRoute
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with $hr.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $hr.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- range $hr.parentRefs }}
    {{- if kindIs "string" . }}
    - name: {{ . }}
    {{- else }}
    - {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- end }}
  {{- with $hr.hostnames }}
  hostnames:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $hr.rules }}
  rules:
    {{- toYaml $hr.rules | nindent 4 }}
  {{- else if $hr.paths }}
  rules:
  {{- range $hr.paths }}
  - matches:
      - path:
          type: {{ .pathType | default "PathPrefix" }}
          value: {{ .path | quote }}
    backendRefs:
      - name: {{ (.destination).name | default $fullName }}
        port: {{ (.destination).port | default $svcPort }}
        {{- with (.destination).weight }}
        weight: {{ . }}
        {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
