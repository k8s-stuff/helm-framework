# helm-framework-test-template

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Helm Framework Test Template chart

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://..//helm-framework | helm-framework | * |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| appSettings.test1.test2 | bool | `true` |  |
| appSettings.testSetting | string | `"testValue"` |  |
| authorizationPolicy[0].action | string | `"ALLOW"` |  |
| authorizationPolicy[0].enabled | bool | `true` |  |
| authorizationPolicy[0].name | string | `"allow-frontend"` |  |
| authorizationPolicy[0].rules[0].from[0].source.principals[0] | string | `"cluster.local/ns/team-a/sa/frontend"` |  |
| authorizationPolicy[0].rules[0].to[0].operation.methods[0] | string | `"GET"` |  |
| authorizationPolicy[0].rules[0].to[0].operation.methods[1] | string | `"POST"` |  |
| authorizationPolicy[0].rules[0].to[0].operation.paths[0] | string | `"/api/*"` |  |
| authorizationPolicy[0].rules[0].when[0].key | string | `"request.headers[x-env]"` |  |
| authorizationPolicy[0].rules[0].when[0].values[0] | string | `"prod"` |  |
| authorizationPolicy[1].action | string | `"DENY"` |  |
| authorizationPolicy[1].enabled | bool | `true` |  |
| authorizationPolicy[1].name | string | `"deny-legacy"` |  |
| authorizationPolicy[1].rules[0].to[0].operation.paths[0] | string | `"/legacy/*"` |  |
| envVarsFromSecret.secretKey | string | `"secretValue"` |  |
| envVars[0].name | string | `"foo"` |  |
| envVars[0].value | string | `"bar"` |  |
| envVars[1].name | string | `"key"` |  |
| envVars[1].value | string | `"value"` |  |
| externalSecrets.app-secret-bulk.dataFrom[0].extract.key | string | `"my-other-secret"` |  |
| externalSecrets.app-secret-bulk.secretStoreRef.kind | string | `"SecretStore"` |  |
| externalSecrets.app-secret-bulk.secretStoreRef.name | string | `"app-secretstore"` |  |
| externalSecrets.app-secret.data[0].remoteRef.key | string | `"my-secret"` |  |
| externalSecrets.app-secret.data[0].remoteRef.property | string | `"username"` |  |
| externalSecrets.app-secret.data[0].secretKey | string | `"username"` |  |
| externalSecrets.app-secret.data[1].remoteRef.key | string | `"my-secret"` |  |
| externalSecrets.app-secret.data[1].remoteRef.property | string | `"password"` |  |
| externalSecrets.app-secret.data[1].secretKey | string | `"password"` |  |
| externalSecrets.app-secret.refreshInterval | string | `"1h"` |  |
| externalSecrets.app-secret.secretStoreRef.kind | string | `"SecretStore"` |  |
| externalSecrets.app-secret.secretStoreRef.name | string | `"app-secretstore"` |  |
| externalSecrets.app-secret.target.creationPolicy | string | `"Owner"` |  |
| externalSecrets.app-secret.target.name | string | `"app-secret"` |  |
| forceReload | bool | `false` |  |
| fullnameOverride | string | `""` |  |
| healthChecks.enabled | bool | `true` |  |
| healthChecks.livenessProbe.failureThreshold | int | `10` |  |
| healthChecks.livenessProbe.initialDelaySeconds | int | `1` |  |
| healthChecks.livenessProbe.path | string | `"/health/liveness"` |  |
| healthChecks.livenessProbe.periodSeconds | int | `10` |  |
| healthChecks.livenessProbe.successThreshold | int | `1` |  |
| healthChecks.livenessProbe.timeoutSeconds | int | `3` |  |
| healthChecks.readinessProbe.failureThreshold | int | `3` |  |
| healthChecks.readinessProbe.initialDelaySeconds | int | `1` |  |
| healthChecks.readinessProbe.path | string | `"/health/readiness"` |  |
| healthChecks.readinessProbe.periodSeconds | int | `10` |  |
| healthChecks.readinessProbe.successThreshold | int | `1` |  |
| healthChecks.readinessProbe.timeoutSeconds | int | `3` |  |
| healthChecks.startupProbe.failureThreshold | int | `30` |  |
| healthChecks.startupProbe.initialDelaySeconds | int | `10` |  |
| healthChecks.startupProbe.path | string | `"/health/startup"` |  |
| healthChecks.startupProbe.periodSeconds | int | `5` |  |
| healthChecks.startupProbe.successThreshold | int | `1` |  |
| healthChecks.startupProbe.timeoutSeconds | int | `3` |  |
| helmFrameworkSettings.configFileName | string | `"appsettings.Production.json"` |  |
| helmFrameworkSettings.configPath | string | `"/app"` |  |
| horizontalPodAutoscaler.behavior.scaleDown.policies[0].periodSeconds | int | `15` |  |
| horizontalPodAutoscaler.behavior.scaleDown.policies[0].type | string | `"Percent"` |  |
| horizontalPodAutoscaler.behavior.scaleDown.policies[0].value | int | `100` |  |
| horizontalPodAutoscaler.behavior.scaleDown.stabilizationWindowSeconds | int | `300` |  |
| horizontalPodAutoscaler.enabled | bool | `true` |  |
| horizontalPodAutoscaler.maxReplicas | int | `10` |  |
| horizontalPodAutoscaler.metrics[0].pods.metric.name | string | `"packets-per-second"` |  |
| horizontalPodAutoscaler.metrics[0].pods.target.averageValue | string | `"1k"` |  |
| horizontalPodAutoscaler.metrics[0].pods.target.type | string | `"AverageValue"` |  |
| horizontalPodAutoscaler.metrics[0].type | string | `"Pods"` |  |
| horizontalPodAutoscaler.minReplicas | int | `2` |  |
| horizontalPodAutoscaler.targetCPUUtilizationPercentage | int | `75` |  |
| horizontalPodAutoscaler.targetMemoryUtilizationPercentage | int | `80` |  |
| hostAliases | list | `[]` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"alpine"` |  |
| image.tag | string | `"1.0.0"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations."kubernetes.io/tls-acme" | string | `"true"` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hosts[0].host | string | `"app.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls[0].hosts[0] | string | `"app.local"` |  |
| ingress.tls[0].secretName | string | `"app-local-tls"` |  |
| initContainer.caBundle.enabled | bool | `true` |  |
| initContainer.caBundle.trustedCertificateAuthorities."corporate-root-ca.crt" | string | `"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmR1bW15LWNhCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"` |  |
| initContainer.waitFor | object | `{}` |  |
| initContainers[0].command[0] | string | `"sh"` |  |
| initContainers[0].command[1] | string | `"-c"` |  |
| initContainers[0].command[2] | string | `"until nc -z mydb 5432; do echo waiting for db; sleep 2; done;"` |  |
| initContainers[0].image | string | `"busybox:1.28"` |  |
| initContainers[0].name | string | `"wait-for-database"` |  |
| initContainers[1].command[0] | string | `"sh"` |  |
| initContainers[1].command[1] | string | `"-c"` |  |
| initContainers[1].command[2] | string | `"chmod -R 755 /data"` |  |
| initContainers[1].image | string | `"alpine:latest"` |  |
| initContainers[1].name | string | `"setup-permissions"` |  |
| jobs[0].args[0] | string | `"echo running migrations"` |  |
| jobs[0].backoffLimit | int | `6` |  |
| jobs[0].command[0] | string | `"/bin/sh"` |  |
| jobs[0].command[1] | string | `"-c"` |  |
| jobs[0].enabled | bool | `true` |  |
| jobs[0].envVars[0].name | string | `"JOB_MODE"` |  |
| jobs[0].envVars[0].value | string | `"migrate"` |  |
| jobs[0].name | string | `"migrate"` |  |
| jobs[0].restartPolicy | string | `"OnFailure"` |  |
| jobs[0].waitForIt | bool | `true` |  |
| keda.enabled | bool | `false` |  |
| keda.scaledObject.cooldownPeriod | int | `300` |  |
| keda.scaledObject.maxReplicaCount | int | `10` |  |
| keda.scaledObject.minReplicaCount | int | `1` |  |
| keda.scaledObject.pollingInterval | int | `30` |  |
| keda.scaledObject.scaleTargetRef.apiVersion | string | `"apps/v1"` |  |
| keda.scaledObject.scaleTargetRef.envSourceContainerName | string | `""` |  |
| keda.scaledObject.scaleTargetRef.kind | string | `"Deployment"` |  |
| keda.scaledObject.scaleTargetRef.name | string | `""` |  |
| keda.scaledObject.triggers[0].authenticationRef.name | string | `"test-trigger-auth"` |  |
| keda.scaledObject.triggers[0].metadata.metricName | string | `"http_requests_per_second"` |  |
| keda.scaledObject.triggers[0].metadata.query | string | `"sum(rate(http_requests_total[1m]))"` |  |
| keda.scaledObject.triggers[0].metadata.serverAddress | string | `"http://prometheus.monitoring.svc.cluster.local:9090"` |  |
| keda.scaledObject.triggers[0].metadata.threshold | string | `"10"` |  |
| keda.scaledObject.triggers[0].type | string | `"prometheus"` |  |
| keda.triggerAuthentication.name | string | `"test-trigger-auth"` |  |
| keda.triggerAuthentication.secretTargetRef[0].key | string | `"connectionString"` |  |
| keda.triggerAuthentication.secretTargetRef[0].name | string | `"keda-secret"` |  |
| keda.triggerAuthentication.secretTargetRef[0].parameter | string | `"connection"` |  |
| nameOverride | string | `"helm-framework-test-template"` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| rbac.create | bool | `true` |  |
| rbac.rules[0].apiGroups[0] | string | `""` |  |
| rbac.rules[0].resources[0] | string | `"pods"` |  |
| rbac.rules[0].resources[1] | string | `"services"` |  |
| rbac.rules[0].verbs[0] | string | `"get"` |  |
| rbac.rules[0].verbs[1] | string | `"list"` |  |
| rbac.rules[0].verbs[2] | string | `"watch"` |  |
| rbac.rules[1].apiGroups[0] | string | `"batch"` |  |
| rbac.rules[1].resources[0] | string | `"jobs"` |  |
| rbac.rules[1].verbs[0] | string | `"get"` |  |
| rbac.rules[1].verbs[1] | string | `"list"` |  |
| rbac.rules[1].verbs[2] | string | `"watch"` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"200m"` |  |
| resources.limits.memory | string | `"256Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| secretStore.annotations."example.com/managed-by" | string | `"helm-framework-test-template"` |  |
| secretStore.spec.provider.gcpsm.auth.secretRef.secretAccessKeySecretRef.key | string | `"secret-access-credentials"` |  |
| secretStore.spec.provider.gcpsm.auth.secretRef.secretAccessKeySecretRef.name | string | `"gcpsm-secret"` |  |
| secretStore.spec.provider.gcpsm.projectID | string | `"my-project"` |  |
| securityContext | object | `{}` |  |
| service.annotations | object | `{}` |  |
| service.port | int | `80` |  |
| service.sessionAffinity | string | `"ClientIP"` |  |
| service.sessionAffinityConfig.clientIPTimeoutSeconds | int | `600` |  |
| service.targetPort | int | `8080` |  |
| service.targetScheme | string | `"HTTP"` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `false` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| sidecars[0].appSettings.proxySetting | string | `"proxyValue"` |  |
| sidecars[0].enabled | bool | `true` |  |
| sidecars[0].image.pullPolicy | string | `"IfNotPresent"` |  |
| sidecars[0].image.repository | string | `"alpine"` |  |
| sidecars[0].image.tag | string | `"1.0.0"` |  |
| sidecars[0].name | string | `"proxy"` |  |
| sidecars[0].service.port | int | `8081` |  |
| sidecars[0].service.targetPort | int | `8080` |  |
| sidecars[0].service.targetScheme | string | `"HTTP"` |  |
| strategy | object | `{}` |  |
| tls.certFile | string | `"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmR1bW15LWNlcnQKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ=="` |  |
| tls.enabled | bool | `true` |  |
| tls.keyFile | string | `"LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCmR1bW15LWtleQotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCg=="` |  |
| tls.mountPath | string | `"/mnt/tls"` |  |
| tolerations | list | `[]` |  |
| verticalPodAutoscaler.containerPolicies[0].containerName | string | `"*"` |  |
| verticalPodAutoscaler.containerPolicies[0].controlledResources[0] | string | `"cpu"` |  |
| verticalPodAutoscaler.containerPolicies[0].controlledResources[1] | string | `"memory"` |  |
| verticalPodAutoscaler.containerPolicies[0].controlledValues | string | `"RequestsAndLimits"` |  |
| verticalPodAutoscaler.containerPolicies[0].maxAllowed.cpu | string | `"2"` |  |
| verticalPodAutoscaler.containerPolicies[0].maxAllowed.memory | string | `"2Gi"` |  |
| verticalPodAutoscaler.containerPolicies[0].minAllowed.cpu | string | `"50m"` |  |
| verticalPodAutoscaler.containerPolicies[0].minAllowed.memory | string | `"128Mi"` |  |
| verticalPodAutoscaler.enabled | bool | `true` |  |
| verticalPodAutoscaler.updatePolicy.updateMode | string | `"Off"` |  |
| virtualService.enabled | bool | `true` |  |
| virtualService.gateways[0] | string | `"ingress-gateway"` |  |
| virtualService.hosts[0] | string | `"app.local"` |  |
| virtualService.paths[0].matchType | string | `"prefix"` |  |
| virtualService.paths[0].path | string | `"/api"` |  |
| virtualService.paths[0].retries.attempts | int | `3` |  |
| virtualService.paths[0].retries.perTryTimeout | string | `"2s"` |  |
| virtualService.paths[0].rewriteUri | string | `"/"` |  |
| virtualService.paths[0].timeout | string | `"5s"` |  |
| virtualService.paths[1].destination.port | int | `8080` |  |
| virtualService.paths[1].path | string | `"/health"` |  |
| virtualService.rewriteUri | string | `"/"` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
