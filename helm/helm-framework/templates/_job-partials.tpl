{{/*
Shared Job pod-spec fragments, included by both _job.yaml (the `jobs[]` list)
and _liquibase.tpl (the native Liquibase migration Job). Extracted so the two
Job kinds cannot drift on CA-bundle wiring, VPA-aware resources, appSettings
mounting, or scheduling.

Every partial emits at relative indent 0; callers apply `nindent`. Always pipe
through `trim` first: several partials open with a conditional that leaves a
leading newline, and `nindent` would turn that into a line of bare
indentation. Partials that can emit nothing are additionally wrapped by
callers in `with (include ... | trim)` so an empty result contributes no
whitespace at all.

Context is the chart root ($ / $root) except helm-framework.job.resources,
which takes a dict — see its own comment.
*/}}

{{- define "helm-framework.job.podAnnotations" -}}
checksum/appSettings: {{ .Values.appSettings | default dict | toYaml | sha256sum }}
checksum/application: {{ .Values.helmFrameworkSettings | default dict | toYaml | sha256sum }}
{{- with .Values.podAnnotations }}
{{ toYaml . | trim }}
{{- end }}
{{- end }}

{{- define "helm-framework.job.podLabels" -}}
{{ include "helm-framework.labels" . }}
{{- with .Values.podLabels }}
{{ toYaml . | trim }}
{{- end }}
{{- end }}

{{- define "helm-framework.job.caBundleInit" -}}
- name: ca-bundle-init
  image: "{{ required "Image repository is required!" (.Values.image).repository }}:{{ (.Values.image).tag | default .Chart.AppVersion }}"
  imagePullPolicy: {{ (.Values.image).pullPolicy | default "IfNotPresent" }}
  {{- with .Values.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  command:
    - /bin/sh
  args:
    - -c
    - /mnt/scripts/combine-certs.sh
  volumeMounts:
    - name: scripts
      mountPath: /mnt/scripts
    - name: cert-combine
      mountPath: /mnt/ca-certs
    - name: authorities
      mountPath: /mnt/authorities
{{- end }}

{{/*
VPA-aware resources block. Under an enabled verticalPodAutoscaler only
requests are rendered (limits are the VPA's to manage); otherwise the
resources map is emitted verbatim. Expects a dict:
  { root: <chart root context>, resources: <resolved resources map or nil> }
*/}}
{{- define "helm-framework.job.resources" -}}
{{- $root := .root -}}
{{- $res := .resources -}}
{{- if ($root.Values.verticalPodAutoscaler).enabled }}
{{- with ($res).requests }}
resources:
  requests:
    {{- toYaml . | nindent 4 }}
{{- else }}
resources: {}
{{- end }}
{{- else if $res }}
resources:
  {{- toYaml $res | nindent 2 }}
{{- else }}
resources: {}
{{- end }}
{{- end }}

{{- define "helm-framework.job.commonVolumes" -}}
{{- if .Values.appSettings }}
- name: app-settings
  secret:
    secretName: {{ include "helm-framework.secret-app-settings" . }}
    optional: false
{{- end }}
{{- if ((.Values.initContainer).caBundle).enabled }}
- name: cert-combine
  emptyDir: {}
- name: scripts
  secret:
    secretName: {{ include "helm-framework.secret-scripts" . }}
    optional: false
    defaultMode: 0555
- name: authorities
  secret:
    secretName: {{ include "helm-framework.secret-authorities" . }}
    optional: false
{{- end }}
{{- end }}

{{- define "helm-framework.job.commonVolumeMounts" -}}
{{- if .Values.appSettings }}
- name: app-settings
  mountPath: "{{ include "helm-framework.values.application.configPath" . }}/{{ include "helm-framework.values.configFileName" . }}"
  subPath: {{ include "helm-framework.values.configFileName" . | quote }}
  readOnly: true
{{- end }}
{{- if ((.Values.initContainer).caBundle).enabled }}
- name: cert-combine
  mountPath: {{ include "helm-framework.values.ca-bundle-path" . }}
  readOnly: true
{{- end }}
{{- end }}

{{- define "helm-framework.job.scheduling" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
