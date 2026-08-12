{{- define "helm-framework.deployment.role-binding" -}}
{{- if (.Values.rbac).create }}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "helm-framework.fullname" . }}-role-binding
  labels:
    {{- include "helm-framework.labels" . | nindent 4 }}
    {{- with (.Values.rbac).labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-weight: "-20"
    {{- with (.Values.rbac).annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
roleRef:
{{- if (.Values.rbac).roleRef }}
  {{- toYaml .Values.rbac.roleRef | nindent 2 }}
{{- else }}
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "helm-framework.rbac.roleName" . }}
{{- end }}
subjects:
  - kind: ServiceAccount
    name: {{ include "helm-framework.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
{{- end }}
{{- end }}
