# helm-framework values contract (v1.1.0)

Generated from `helm/helm-framework/templates/` and `helm/helm-framework/values.yaml`.
Do not edit by hand. This is what the migration playbook uses to classify a
consumer's leftover `values.yaml` keys as read, unread, or unknown.

## Top-level keys are authoritative

The list below comes from grepping `.Values.<name>` across every template in
`helm/helm-framework/templates/`. It is the exact set of top-level keys the
library reads, and generation fails if it ever disagrees with
`values.yaml`'s own top-level keys (an explicit allowlist covers deliberate
exceptions). Treat this list as ground truth: a top-level consumer key that
is **not** in this list is not read by the library, full stop.

- `affinity`
- `appSettings`
- `args`
- `authorizationPolicy`
- `command`
- `envVars`
- `envVarsFromSecret`
- `externalSecrets`
- `forceReload`
- `fullnameOverride`
- `healthChecks`
- `helmFrameworkSettings`
- `horizontalPodAutoscaler`
- `hostAliases`
- `httpRoute`
- `image`
- `imagePullSecrets`
- `ingress`
- `initContainer`
- `initContainers`
- `jobs`
- `keda`
- `nameOverride`
- `nodeSelector`
- `podAnnotations`
- `podDisruptionBudget`
- `podLabels`
- `podSecurityContext`
- `rbac`
- `replicaCount`
- `resources`
- `secretStore`
- `securityContext`
- `service`
- `serviceAccount`
- `sidecars`
- `strategy`
- `tls`
- `tolerations`
- `verticalPodAutoscaler`
- `virtualService`
- `volumeMounts`
- `volumes`

## Nested paths are declared-surface only — not grep-verified

The list below is `values.yaml`'s own declared key tree (dotted paths,
derived from indentation). Unlike the top-level list above, **this is not a
readership proof.**

Why: deep access inside the library frequently goes through helper indirection,
e.g. `include "helm-framework.values.service.port"` rather than a literal
`.Values.service.port` appearing in a template. Grepping for a literal nested
path is therefore provably incomplete — it misses every value read through a
helper. So:

- a nested path appearing here is *plausible*, but not proven read
- a nested path missing here may still be legitimately consumed by its
  top-level parent through a helper

**Do not auto-remove a consumer's nested key on the strength of this list
alone.** The migration playbook only auto-removes what it can also prove via
a byte-identical re-render — this list is for reasoning about plausibility,
not for authorizing deletion.

- `affinity`
- `appSettings`
- `args`
- `authorizationPolicy`
- `command`
- `envVars`
- `envVarsFromSecret`
- `externalSecrets`
- `forceReload`
- `fullnameOverride`
- `healthChecks`
- `healthChecks.enabled`
- `healthChecks.livenessProbe`
- `healthChecks.livenessProbe.failureThreshold`
- `healthChecks.livenessProbe.initialDelaySeconds`
- `healthChecks.livenessProbe.path`
- `healthChecks.livenessProbe.periodSeconds`
- `healthChecks.livenessProbe.successThreshold`
- `healthChecks.livenessProbe.timeoutSeconds`
- `healthChecks.readinessProbe`
- `healthChecks.readinessProbe.failureThreshold`
- `healthChecks.readinessProbe.initialDelaySeconds`
- `healthChecks.readinessProbe.path`
- `healthChecks.readinessProbe.periodSeconds`
- `healthChecks.readinessProbe.successThreshold`
- `healthChecks.readinessProbe.timeoutSeconds`
- `healthChecks.startupProbe`
- `healthChecks.startupProbe.failureThreshold`
- `healthChecks.startupProbe.initialDelaySeconds`
- `healthChecks.startupProbe.path`
- `healthChecks.startupProbe.periodSeconds`
- `healthChecks.startupProbe.successThreshold`
- `healthChecks.startupProbe.timeoutSeconds`
- `helmFrameworkSettings`
- `helmFrameworkSettings.configFileName`
- `helmFrameworkSettings.configPath`
- `horizontalPodAutoscaler`
- `horizontalPodAutoscaler.annotations`
- `horizontalPodAutoscaler.behavior`
- `horizontalPodAutoscaler.enabled`
- `horizontalPodAutoscaler.labels`
- `horizontalPodAutoscaler.maxReplicas`
- `horizontalPodAutoscaler.metrics`
- `horizontalPodAutoscaler.minReplicas`
- `horizontalPodAutoscaler.scaleTargetRef`
- `horizontalPodAutoscaler.targetCPUUtilizationPercentage`
- `horizontalPodAutoscaler.targetMemoryUtilizationPercentage`
- `hostAliases`
- `httpRoute`
- `httpRoute.annotations`
- `httpRoute.enabled`
- `httpRoute.hostnames`
- `httpRoute.labels`
- `httpRoute.parentRefs`
- `httpRoute.paths`
- `httpRoute.rules`
- `image`
- `image.pullPolicy`
- `image.repository`
- `image.tag`
- `imagePullSecrets`
- `ingress`
- `ingress.annotations`
- `ingress.className`
- `ingress.enabled`
- `ingress.hosts`
- `ingress.tls`
- `initContainer`
- `initContainer.caBundle`
- `initContainer.caBundle.enabled`
- `initContainer.caBundle.trustedCertificateAuthorities`
- `initContainer.waitFor`
- `initContainer.waitFor.args`
- `initContainer.waitFor.command`
- `initContainer.waitFor.image`
- `initContainer.waitFor.image.pullPolicy`
- `initContainer.waitFor.image.repository`
- `initContainer.waitFor.image.tag`
- `initContainer.waitFor.timeout`
- `initContainers`
- `jobs`
- `keda`
- `keda.enabled`
- `keda.scaledObject`
- `keda.scaledObject.advanced`
- `keda.scaledObject.annotations`
- `keda.scaledObject.cooldownPeriod`
- `keda.scaledObject.fallback`
- `keda.scaledObject.idleReplicaCount`
- `keda.scaledObject.maxReplicaCount`
- `keda.scaledObject.minReplicaCount`
- `keda.scaledObject.pollingInterval`
- `keda.scaledObject.scaleTargetRef`
- `keda.scaledObject.scaleTargetRef.apiVersion`
- `keda.scaledObject.scaleTargetRef.envSourceContainerName`
- `keda.scaledObject.scaleTargetRef.kind`
- `keda.scaledObject.scaleTargetRef.name`
- `keda.scaledObject.triggers`
- `keda.triggerAuthentication`
- `keda.triggerAuthentication.env`
- `keda.triggerAuthentication.name`
- `keda.triggerAuthentication.podIdentity`
- `keda.triggerAuthentication.secretTargetRef`
- `nameOverride`
- `nodeSelector`
- `podAnnotations`
- `podDisruptionBudget`
- `podDisruptionBudget.annotations`
- `podDisruptionBudget.enabled`
- `podDisruptionBudget.labels`
- `podDisruptionBudget.maxUnavailable`
- `podDisruptionBudget.minAvailable`
- `podLabels`
- `podSecurityContext`
- `rbac`
- `rbac.annotations`
- `rbac.create`
- `rbac.labels`
- `rbac.roleRef`
- `rbac.rules`
- `replicaCount`
- `resources`
- `secretStore`
- `securityContext`
- `service`
- `service.annotations`
- `service.externalTrafficPolicy`
- `service.port`
- `service.sessionAffinity`
- `service.sessionAffinityConfig`
- `service.sessionAffinityConfig.clientIPTimeoutSeconds`
- `service.targetPort`
- `service.targetScheme`
- `service.type`
- `serviceAccount`
- `serviceAccount.annotations`
- `serviceAccount.automount`
- `serviceAccount.create`
- `serviceAccount.name`
- `sidecars`
- `strategy`
- `tls`
- `tls.certFile`
- `tls.enabled`
- `tls.keyFile`
- `tls.mountPath`
- `tolerations`
- `verticalPodAutoscaler`
- `verticalPodAutoscaler.annotations`
- `verticalPodAutoscaler.containerPolicies`
- `verticalPodAutoscaler.defaultContainerPolicy`
- `verticalPodAutoscaler.defaultContainerPolicy.containerName`
- `verticalPodAutoscaler.defaultContainerPolicy.controlledResources`
- `verticalPodAutoscaler.defaultContainerPolicy.maxAllowed`
- `verticalPodAutoscaler.defaultContainerPolicy.minAllowed`
- `verticalPodAutoscaler.defaultContainerPolicy.minAllowed.cpu`
- `verticalPodAutoscaler.defaultContainerPolicy.minAllowed.memory`
- `verticalPodAutoscaler.enabled`
- `verticalPodAutoscaler.labels`
- `verticalPodAutoscaler.recommenders`
- `verticalPodAutoscaler.targetRef`
- `verticalPodAutoscaler.updatePolicy`
- `verticalPodAutoscaler.updatePolicy.updateMode`
- `virtualService`
- `virtualService.annotations`
- `virtualService.enabled`
- `virtualService.gateways`
- `virtualService.hosts`
- `virtualService.http`
- `virtualService.labels`
- `virtualService.paths`
- `virtualService.rewriteUri`
- `virtualService.tcp`
- `virtualService.tls`
- `volumeMounts`
- `volumes`
