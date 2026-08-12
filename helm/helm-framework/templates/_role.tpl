{{- define "helm-framework.deployment.role" -}}
{{- if and ((.Values.rbac).create) (not (.Values.rbac).roleRef) }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "helm-framework.rbac.roleName" . }}
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
{{- if (.Values.rbac).rules }}
rules:
  {{- toYaml .Values.rbac.rules | nindent 2 }}
{{- else }}
rules: []
{{- end }}
{{- end }}
{{- end }}

{{/*
Dedicated Role + RoleBinding granting the pod's ServiceAccount read access to
jobs, so the wait-for-job init container can watch job completion. Rendered
whenever a job is flagged `waitForIt: true`. Kept separate from the main RBAC
Role so it is purely additive — it works alongside `rbac.create`, a custom
`rbac.roleRef`, or no user RBAC at all.
*/}}
{{- define "helm-framework.deployment.waitFor.rbac" -}}
{{- if include "helm-framework.waitFor.active" . }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "helm-framework.fullname" . }}-wait-for-jobs
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
rules:
  - apiGroups:
      - batch
    resources:
      - jobs
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "helm-framework.fullname" . }}-wait-for-jobs
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
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "helm-framework.fullname" . }}-wait-for-jobs
subjects:
  - kind: ServiceAccount
    name: {{ include "helm-framework.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
{{- end }}
{{- end }}
