{{- define "helm-framework.values.service.type" -}}
{{- (.Values.service).type | default "ClusterIP" }}
{{- end }}

{{- define "helm-framework.values.service.port" -}}
{{- (.service).port | default ((.Values).service).port | default 80 }}
{{- end }}

{{- define "helm-framework.values.service.targetPort" -}}
{{- (.service).targetPort | default ((.Values).service).targetPort | default 8080 }}
{{- end }}

{{- define "helm-framework.values.service.targetScheme" -}}
{{- (.service).targetScheme | default ((.Values).service).targetScheme | default "HTTP" }}
{{- end }}

{{- define "helm-framework.values.application.configPath" -}}
{{- (.Values.helmFrameworkSettings).configPath | default "/app" | trimSuffix "/" }}
{{- end }}

{{- define "helm-framework.values.configFileName" -}}
{{- (.Values.helmFrameworkSettings).configFileName | default "appsettings.Production.json" }}
{{- end }}

{{- define "helm-framework.values.ca-bundle-path" -}}
/etc/ssl/certs
{{- end }}

{{- define "helm-framework.values.ca-bundle-file-name" -}}
ca-certificates.crt
{{- end }}

{{- define "helm-framework.values.tls.mountPath" -}}
{{- (.Values.tls).mountPath | default "/mnt/tls" }}
{{- end }}

{{- define "helm-framework.values.initContainer.waitFor.image." -}}
{{- (((.Values.initContainer).waitFor).image).repository | default "alpine/kubectl" }}:{{- (((.Values.initContainer).waitFor).image).tag | default "1.34.1" }}
{{- end }}

{{- define "helm-framework.values.affinity" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 50
      podAffinityTerm:
        topologyKey: "kubernetes.io/hostname"
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - {{ include "helm-framework.name" . }}
{{- end }}
