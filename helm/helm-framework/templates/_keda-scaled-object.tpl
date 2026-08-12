{{- define "helm-framework.keda.scaled-object" -}}
{{- if (.Values.keda).enabled }}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {{ include "helm-framework.fullname" . }}-scaledobject
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
  {{- with .Values.keda.scaledObject.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  scaleTargetRef:
    {{- if .Values.keda.scaledObject.scaleTargetRef.apiVersion }}
    apiVersion: {{ .Values.keda.scaledObject.scaleTargetRef.apiVersion }}
    {{- end }}
    {{- if .Values.keda.scaledObject.scaleTargetRef.kind }}
    kind: {{ .Values.keda.scaledObject.scaleTargetRef.kind }}
    {{- end }}
    name: {{ .Values.keda.scaledObject.scaleTargetRef.name | default (include "helm-framework.fullname" .) }}
    {{- if .Values.keda.scaledObject.scaleTargetRef.envSourceContainerName }}
    envSourceContainerName: {{ .Values.keda.scaledObject.scaleTargetRef.envSourceContainerName }}
    {{- end }}
  {{- if .Values.keda.scaledObject.pollingInterval }}
  pollingInterval: {{ .Values.keda.scaledObject.pollingInterval }}
  {{- end }}
  {{- if .Values.keda.scaledObject.cooldownPeriod }}
  cooldownPeriod: {{ .Values.keda.scaledObject.cooldownPeriod }}
  {{- end }}
  {{- if .Values.keda.scaledObject.idleReplicaCount }}
  idleReplicaCount: {{ .Values.keda.scaledObject.idleReplicaCount }}
  {{- end }}
  {{- if .Values.keda.scaledObject.minReplicaCount }}
  minReplicaCount: {{ .Values.keda.scaledObject.minReplicaCount }}
  {{- end }}
  {{- if .Values.keda.scaledObject.maxReplicaCount }}
  maxReplicaCount: {{ .Values.keda.scaledObject.maxReplicaCount }}
  {{- end }}
  {{- if .Values.keda.scaledObject.fallback }}
  fallback:
    failureThreshold: {{ .Values.keda.scaledObject.fallback.failureThreshold }}
    replicas: {{ .Values.keda.scaledObject.fallback.replicas }}
  {{- end }}
  {{- if .Values.keda.scaledObject.advanced }}
  advanced:
    {{- if .Values.keda.scaledObject.advanced.restoreToOriginalReplicaCount }}
    restoreToOriginalReplicaCount: {{ .Values.keda.scaledObject.advanced.restoreToOriginalReplicaCount }}
    {{- end }}
    {{- if .Values.keda.scaledObject.advanced.horizontalPodAutoscalerConfig }}
    horizontalPodAutoscalerConfig:
      {{- if .Values.keda.scaledObject.advanced.horizontalPodAutoscalerConfig.name }}
      name: {{ .Values.keda.scaledObject.advanced.horizontalPodAutoscalerConfig.name }}
      {{- end }}
      {{- if .Values.keda.scaledObject.advanced.horizontalPodAutoscalerConfig.behavior }}
      behavior:
        {{- toYaml .Values.keda.scaledObject.advanced.horizontalPodAutoscalerConfig.behavior | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- if .Values.keda.scaledObject.advanced.scalingPolicy }}
    scalingPolicy:
      {{- toYaml .Values.keda.scaledObject.advanced.scalingPolicy | nindent 6 }}
    {{- end }}
  {{- end }}
  triggers:
    {{- range .Values.keda.scaledObject.triggers }}
    - type: {{ .type }}
      {{- if .name }}
      name: {{ .name }}
      {{- end }}
      {{- if .metadata }}
      metadata:
        {{- range $key, $value := .metadata }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
      {{- end }}
      {{- if .metricType }}
      metricType: {{ .metricType }}
      {{- end }}
      {{- if .authenticationRef }}
      authenticationRef:
        name: {{ .authenticationRef.name | default (($.Values.keda.triggerAuthentication).name | default (printf "%s-trigger-auth" (include "helm-framework.fullname" $))) }}
        {{- if .authenticationRef.kind }}
        kind: {{ .authenticationRef.kind }}
        {{- end }}
      {{- end }}
      {{- if .useCachedMetrics }}
      useCachedMetrics: {{ .useCachedMetrics }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}
