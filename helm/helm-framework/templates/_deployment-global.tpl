{{- define "helm-framework.deployment.global" -}}
{{- include "helm-framework.keda.validate" . -}}
{{- include "helm-framework.autoscaling.validate" . -}}
{{- include "helm-framework.values.validate" . -}}
{{- $documents := list
    (include "helm-framework.deployment.deploy" .)
    (include "helm-framework.deployment.pdb" .)
    (include "helm-framework.deployment.secret-tls" .)
    (include "helm-framework.deployment.job" .)
    (include "helm-framework.deployment.secret-scripts" .)
    (include "helm-framework.deployment.secret-authorities" .)
    (include "helm-framework.deployment.secret-env" .)
    (include "helm-framework.deployment.secret-sidecar-env" .)
    (include "helm-framework.deployment.secret-app-settings" .)
    (include "helm-framework.deployment.secret-sidecar-app-settings" .)
    (include "helm-framework.deployment.secretstore" .)
    (include "helm-framework.deployment.externalsecret" .)
    (include "helm-framework.deployment.hpa" .)
    (include "helm-framework.deployment.vpa" .)
    (include "helm-framework.deployment.authorizationPolicy" .)
    (include "helm-framework.deployment.ingress" .)
    (include "helm-framework.deployment.service" .)
    (include "helm-framework.deployment.virtual-service" .)
    (include "helm-framework.deployment.httproute" .)
    (include "helm-framework.deployment.serviceAccount" .)
    (include "helm-framework.deployment.role" .)
    (include "helm-framework.deployment.role-binding" .)
    (include "helm-framework.deployment.waitFor.rbac" .)
    (include "helm-framework.keda.trigger-authentication" .)
    (include "helm-framework.keda.scaled-object" .)
-}}
{{- /* helm-framework.keda.validate / helm-framework.autoscaling.validate only ever `fail`; they are invoked above (outside $documents) purely for their side effect and emit no document. */ -}}
{{- range $documents }}
{{- with trim . }}
---
{{ . }}
{{- end }}
{{- end }}
{{- end }}
