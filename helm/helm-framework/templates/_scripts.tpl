{{- define "helm-framework.scripts.combine-certs" -}}
cat {{include "helm-framework.values.ca-bundle-path" .}}/{{include "helm-framework.values.ca-bundle-file-name" .}} /mnt/authorities/* > /mnt/ca-certs/{{include "helm-framework.values.ca-bundle-file-name" .}}
{{- end}}
