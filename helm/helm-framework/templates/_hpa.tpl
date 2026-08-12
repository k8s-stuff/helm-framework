{{- define "helm-framework.deployment.hpa" -}}
{{- $hpa := .Values.horizontalPodAutoscaler | default dict -}}
{{- if $hpa.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "helm-framework.fullname" . }}
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with $hpa.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $hpa.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  scaleTargetRef:
    {{- if $hpa.scaleTargetRef }}
    {{- toYaml $hpa.scaleTargetRef | nindent 4 }}
    {{- else }}
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "helm-framework.fullname" . }}
    {{- end }}
  minReplicas: {{ $hpa.minReplicas | default 1 }}
  maxReplicas: {{ required "horizontalPodAutoscaler.maxReplicas is required when the HPA is enabled" $hpa.maxReplicas }}
  {{- if or $hpa.targetCPUUtilizationPercentage $hpa.targetMemoryUtilizationPercentage $hpa.metrics }}
  metrics:
    {{- if $hpa.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $hpa.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $hpa.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $hpa.targetMemoryUtilizationPercentage }}
    {{- end }}
    {{- with $hpa.metrics }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $hpa.behavior }}
  behavior:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
