{{- define "helm-framework.deployment.virtual-service" -}}
{{- $vs := .Values.virtualService | default dict -}}
{{- $fullName := include "helm-framework.fullname" . -}}
{{- $svcPort := (include "helm-framework.values.service.port" .) -}}
{{- if $vs.enabled -}}
apiVersion: {{ $vs.apiVersion | default "networking.istio.io/v1beta1" }}
kind: VirtualService
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with $vs.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $vs.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with $vs.exportTo }}
  exportTo:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  gateways:
  {{- if kindIs "slice" $vs.gateways }}
    {{- toYaml $vs.gateways | nindent 4 }}
  {{- else }}
    - {{ $vs.gateways }}
  {{- end }}
  hosts:
  {{- if kindIs "slice" $vs.hosts }}
    {{- toYaml $vs.hosts | nindent 4 }}
  {{- else }}
    - {{ $vs.hosts }}
  {{- end }}
  {{- if $vs.http }}
  http:
    {{- toYaml $vs.http | nindent 4 }}
  {{- else if $vs.paths }}
  http:
  {{- range $index, $p := $vs.paths }}
  - name: {{ $fullName }}-{{ $index }}
    match:
    - uri:
        {{ $p.matchType | default "prefix" }}: {{ $p.path | quote }}
    {{- $rewrite := $p.rewriteUri | default $vs.rewriteUri }}
    {{- if $rewrite }}
    rewrite:
      uri: {{ $rewrite | quote }}
    {{- end }}
    {{- with $p.timeout }}
    timeout: {{ . }}
    {{- end }}
    {{- with $p.retries }}
    retries:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    route:
    - destination:
        host: {{ ($p.destination).host | default $fullName }}
        {{- with ($p.destination).subset }}
        subset: {{ . }}
        {{- end }}
        port:
          number: {{ ($p.destination).port | default $svcPort }}
      {{- with ($p.destination).weight }}
      weight: {{ . }}
      {{- end }}
  {{- end }}
  {{- end }}
  {{- with $vs.tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $vs.tcp }}
  tcp:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
