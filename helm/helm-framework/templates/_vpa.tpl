{{- define "helm-framework.deployment.vpa" -}}
{{- $vpa := .Values.verticalPodAutoscaler | default dict -}}
{{- if $vpa.enabled }}
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: {{ include "helm-framework.fullname" . }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with $vpa.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $vpa.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  targetRef:
    {{- if $vpa.targetRef }}
    {{- toYaml $vpa.targetRef | nindent 4 }}
    {{- else }}
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "helm-framework.fullname" . }}
    {{- end }}
  updatePolicy:
    updateMode: {{ ($vpa.updatePolicy).updateMode | default "Off" | quote }}
    {{- if ($vpa.updatePolicy).minReplicas }}
    minReplicas: {{ $vpa.updatePolicy.minReplicas }}
    {{- end }}
  {{- with $vpa.recommenders }}
  recommenders:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  resourcePolicy:
    containerPolicies:
    {{- $policies := $vpa.containerPolicies | default (list ($vpa.defaultContainerPolicy | default dict)) }}
    {{- range $policy := $policies }}
      - containerName: {{ $policy.containerName | default "*" | quote }}
        {{- $rest := omit $policy "containerName" }}
        {{- if $rest }}
        {{- toYaml $rest | nindent 8 }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Resolves the effective VPA controlledValues ("RequestsAndLimits" | "RequestsOnly")
for a specific container name, matching containerPolicies by exact containerName
first, falling back to a "*" wildcard entry, then to VPA's own default. Expects
a dict: { root, containerName }.
*/}}
{{- define "helm-framework.vpa.controlledValues" -}}
{{- $vpa := $.root.Values.verticalPodAutoscaler | default dict -}}
{{- $policies := $vpa.containerPolicies | default (list ($vpa.defaultContainerPolicy | default dict)) -}}
{{- $exact := dict -}}
{{- $wildcard := dict -}}
{{- range $policy := $policies -}}
  {{- $name := $policy.containerName | default "*" -}}
  {{- if eq $name $.containerName -}}
    {{- $exact = $policy -}}
  {{- else if eq $name "*" -}}
    {{- $wildcard = $policy -}}
  {{- end -}}
{{- end -}}
{{- $effective := $wildcard -}}
{{- if $exact -}}
  {{- $effective = $exact -}}
{{- end -}}
{{- $effective.controlledValues | default "RequestsAndLimits" -}}
{{- end -}}
