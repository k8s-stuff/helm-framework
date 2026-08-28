{{/*
The native Liquibase migration Job. A pre-install/pre-upgrade hook at weight
-10 — after the changelog/migrations ConfigMaps and the credentials Secret at
-20, and before the release's own manifests — so the migration runs ahead of
the Deployment. `before-hook-creation` deletion means a re-run replaces the
previous Job rather than colliding with it.

Pod-spec fragments are shared with the `jobs[]` Job via _job-partials.tpl; see
the spec's "Refactor: shared Job partials" section for why this template is
standalone rather than a synthetic jobs[] entry.
*/}}
{{- define "helm-framework.deployment.liquibase" -}}
{{- if (.Values.liquibase).enabled -}}
{{- $lb := .Values.liquibase -}}
{{- $res := ($lb.resources | default .Values.resources) -}}
{{- $changelogMount := ($lb.changelog).mountPath | default "/liquibase/changelog.xml" -}}
{{- $changelogKey := include "helm-framework.liquibase.changelog-key" . -}}
{{- $hasMigrations := eq (include "helm-framework.liquibase.has-migrations" .) "true" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "helm-framework.liquibase.job-name" . }}
  annotations:
    helm.sh/hook: pre-upgrade, pre-install
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "-10"
  labels:
    job: {{ include "helm-framework.liquibase.job-name" . }}
    {{- include "helm-framework.labels" . | nindent 4 }}
spec:
  backoffLimit: {{ $lb.backoffLimit | default 6 | int }}
  template:
    metadata:
      annotations:
        {{- include "helm-framework.job.podAnnotations" . | trim | nindent 8 }}
      labels:
        {{- include "helm-framework.job.podLabels" . | trim | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "helm-framework.serviceAccountName" . }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      restartPolicy: {{ $lb.restartPolicy | default "OnFailure" }}
      {{- if ((.Values.initContainer).caBundle).enabled }}
      initContainers:
        {{- include "helm-framework.job.caBundleInit" . | trim | nindent 8 }}
      {{- end }}
      containers:
        - name: liquibase
          {{- with .Values.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          image: "{{ ($lb.image).repository | default "liquibase/liquibase" }}:{{ ($lb.image).tag | default "4.33" }}"
          imagePullPolicy: {{ ($lb.image).pullPolicy | default "IfNotPresent" }}
          {{- with $lb.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $lb.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          env:
            {{- include "helm-framework.liquibase.env" . | trim | nindent 12 }}
          {{- with $lb.extraEnvFrom }}
          envFrom:
            {{- tpl (toYaml .) $ | nindent 12 }}
          {{- end }}
          {{- include "helm-framework.job.resources" (dict "root" . "resources" $res) | trim | nindent 10 }}
          volumeMounts:
            - name: liquibase-changelog
              mountPath: {{ $changelogMount | quote }}
              subPath: {{ $changelogKey | quote }}
              readOnly: true
            {{- if $hasMigrations }}
            - name: liquibase-migrations
              mountPath: {{ ($lb.migrations).mountPath | default "/liquibase/migrations" | quote }}
              readOnly: true
            {{- end }}
            {{- with (include "helm-framework.job.commonVolumeMounts" . | trim) }}
            {{- . | nindent 12 }}
            {{- end }}
            {{- with $lb.volumeMounts }}
            {{- tpl (toYaml .) $ | nindent 12 }}
            {{- end }}
      volumes:
        - name: liquibase-changelog
          configMap:
            name: {{ include "helm-framework.liquibase.changelog-configmap-name" . }}
            items:
              - key: {{ $changelogKey | quote }}
                path: {{ $changelogKey | quote }}
        {{- if $hasMigrations }}
        - name: liquibase-migrations
          configMap:
            name: {{ include "helm-framework.liquibase.migrations-configmap-name" . }}
        {{- end }}
        {{- with (include "helm-framework.job.commonVolumes" . | trim) }}
        {{- . | nindent 8 }}
        {{- end }}
        {{- with $lb.volumes }}
        {{- tpl (toYaml .) $ | nindent 8 }}
        {{- end }}
      {{- with (include "helm-framework.job.scheduling" . | trim) }}
      {{- . | nindent 6 }}
      {{- end }}
{{- end }}
{{- end }}
