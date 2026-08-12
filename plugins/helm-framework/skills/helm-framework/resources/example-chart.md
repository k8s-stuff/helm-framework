# Example: a chart depending on helm-framework

Copied from `helm-framework-test-template`, the library's own working
example chart.

## Chart.yaml

> The `dependencies:` block below uses a local `file://` path specific to
> this monorepo — copy the OCI or classic-repo dependency snippet from the
> Quick start section above instead.

```yaml
apiVersion: v2
name: "helm-framework-test-template"
description: Helm Framework Test Template chart

type: application

version: 1.0.0

appVersion: "1.0.0"

dependencies:
  - name: helm-framework
    version: "*"
    repository: file://..//helm-framework
```

## values.yaml

```yaml
# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

# Basic deployment settings
replicaCount: 1
forceReload: false
strategy: {}
  # type: RollingUpdate
  # rollingUpdate:
  #   maxSurge: 0
  #   maxUnavailable: 1

# Naming overrides
nameOverride: "helm-framework-test-template"
fullnameOverride: ""

# Image pull secrets
imagePullSecrets: []

# =============================================================================
# CONTAINER IMAGES
# =============================================================================

# Main application image
image:
  repository: alpine
  pullPolicy: IfNotPresent
  tag: "1.0.0"

# Exercise the main container's command/args override so `helm template` renders it.
command: ["/bin/sh"]
args: ["-c", "echo hello && sleep 3600"]

# Init container configuration — both the CA-bundle build and the wait-for-job
# init containers are exercised so `helm template` renders them. The CA-bundle's
# trusted authorities live here (base64-encoded PEM; dummy value for rendering).
initContainer:
  caBundle:
    enabled: true
    trustedCertificateAuthorities:
      corporate-root-ca.crt: "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmR1bW15LWNhCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
  waitFor: {}

# Extra custom init containers — exercised so `helm template` renders them
# appended after the built-in CA-bundle / wait-for-job init containers.
initContainers:
  - name: wait-for-database
    image: busybox:1.28
    command: ['sh', '-c', 'until nc -z mydb 5432; do echo waiting for db; sleep 2; done;']
  - name: setup-permissions
    image: alpine:latest
    command: ['sh', '-c', 'chmod -R 755 /data']
# =============================================================================
# POD & DEPLOYMENT CONFIGURATION
# =============================================================================

# Service account configuration
serviceAccount:
  create: true
  automount: false
  annotations: {}
  name: ""

# RBAC — enabled here so `helm template` exercises Role + RoleBinding wiring.
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["pods", "services"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["batch"]
      resources: ["jobs"]
      verbs: ["get", "list", "watch"]

# Pod configuration
podAnnotations: {}
# Extra pod labels. Example: enable Istio sidecar injection.
podLabels: {}
  # sidecar.istio.io/inject: "true"

# Security contexts
podSecurityContext: {}
  # fsGroup: 2000

securityContext: {}
  # capabilities:
  #   drop:
  #   - ALL
  # readOnlyRootFilesystem: true
  # runAsNonRoot: true
  # runAsUser: 1000

# Host aliases
hostAliases: []
# - ip: "1.2.3.4"
#   hostnames:
#   - "exmaple.com"

# =============================================================================
# NETWORKING
# =============================================================================

# Service configuration. sessionAffinity set here so `helm template`
# exercises sticky sessions.
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
  targetScheme: HTTP
  annotations: {}
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIPTimeoutSeconds: 600

# Ingress — enabled here so `helm template` exercises it (including TLS).
ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/tls-acme: "true"
  hosts:
    - host: app.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: app-local-tls
      hosts:
        - app.local

# Istio VirtualService — enabled here so `helm template` exercises it.
virtualService:
  enabled: true
  gateways:
    - ingress-gateway
  hosts:
    - app.local
  rewriteUri: "/"
  paths:
    - path: /api
      matchType: prefix
      rewriteUri: /
      timeout: 5s
      retries:
        attempts: 3
        perTryTimeout: 2s
    - path: /health
      destination:
        port: 8080

# Gateway API HTTPRoute — enabled here so `helm template` exercises it.
httpRoute:
  enabled: true
  parentRefs:
    - my-gateway
  hostnames:
    - app.local
  paths:
    - path: /
    - path: /api
      pathType: PathPrefix
      destination:
        port: 8080
        weight: 1

# Istio AuthorizationPolicies — two entries so `helm template` exercises the
# multi-policy list (a broad ALLOW plus a targeted DENY).
authorizationPolicy:
  - name: allow-frontend
    enabled: true
    action: ALLOW
    rules:
      - from:
          - source:
              principals: ["cluster.local/ns/team-a/sa/frontend"]
        to:
          - operation:
              methods: ["GET", "POST"]
              paths: ["/api/*"]
        when:
          - key: request.headers[x-env]
            values: ["prod"]
  - name: deny-legacy
    enabled: true
    action: DENY
    rules:
      - to:
          - operation:
              paths: ["/legacy/*"]

# =============================================================================
# HEALTH CHECKS & MONITORING
# =============================================================================

healthChecks:
  enabled: true
  startupProbe:
    path: "/health/startup"
    periodSeconds: 5
    failureThreshold: 30
    successThreshold: 1
    initialDelaySeconds: 10
    timeoutSeconds: 3
  livenessProbe:
    path: "/health/liveness"
    periodSeconds: 10
    failureThreshold: 10
    successThreshold: 1
    initialDelaySeconds: 1
    timeoutSeconds: 3
  readinessProbe:
    path: "/health/readiness"
    periodSeconds: 10
    failureThreshold: 3
    successThreshold: 1
    initialDelaySeconds: 1
    timeoutSeconds: 3

# =============================================================================
# SCALING & RESOURCES
# =============================================================================

# Resource limits and requests — set here because the HPA below scales on
# CPU/memory utilization, which requires requests to compute against.
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Horizontal Pod Autoscaler — enabled here so `helm template` exercises it.
horizontalPodAutoscaler:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 75
  targetMemoryUtilizationPercentage: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
  metrics:
    - type: Pods
      pods:
        metric:
          name: packets-per-second
        target:
          type: AverageValue
          averageValue: 1k

# Vertical Pod Autoscaler — enabled here so `helm template` exercises it.
verticalPodAutoscaler:
  enabled: true
  updatePolicy:
    updateMode: "Off"
  containerPolicies:
    - containerName: "*"
      controlledResources: ["cpu", "memory"]
      controlledValues: RequestsAndLimits
      minAllowed:
        cpu: 50m
        memory: 128Mi
      maxAllowed:
        cpu: "2"
        memory: 2Gi

# =============================================================================
# KEDA AUTOSCALING
# =============================================================================

# KEDA — mutually exclusive with the HorizontalPodAutoscaler above (both
# manage the same Deployment's replicas; the chart now fails fast if both are
# enabled). Disabled by default here; CI renders this chart a second time with
# `--set keda.enabled=true --set horizontalPodAutoscaler.enabled=false` to
# independently exercise the ScaledObject/TriggerAuthentication templates.
keda:
  enabled: false
  triggerAuthentication:
    name: "test-trigger-auth"
    secretTargetRef:
      - parameter: connection
        name: keda-secret
        key: connectionString
  scaledObject:
    scaleTargetRef:
      apiVersion: "apps/v1"
      kind: "Deployment"
      name: ""  # Defaults to the fullname of the chart
      envSourceContainerName: ""
    pollingInterval: 30
    cooldownPeriod: 300
    minReplicaCount: 1
    maxReplicaCount: 10
    triggers:
      - type: prometheus
        metadata:
          serverAddress: "http://prometheus.monitoring.svc.cluster.local:9090"
          metricName: "http_requests_per_second"
          threshold: "10"
          query: "sum(rate(http_requests_total[1m]))"
        authenticationRef:
          name: test-trigger-auth

# =============================================================================
# SECURITY
# =============================================================================

# TLS — enabled here so `helm template` renders the mounted TLS Secret.
# certFile/keyFile hold base64-encoded PEM content (dummy values for rendering).
tls:
  enabled: true
  certFile: "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmR1bW15LWNlcnQKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ=="
  keyFile: "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCmR1bW15LWtleQotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCg=="
  mountPath: "/mnt/tls"

# External Secrets Operator SecretStore — enabled here so `helm template`
# renders it (dummy provider config, not a real credential).
secretStore:
  annotations:
    example.com/managed-by: helm-framework-test-template
  spec:
    provider:
      gcpsm:
        projectID: "my-project"
        auth:
          secretRef:
            secretAccessKeySecretRef:
              name: gcpsm-secret
              key: secret-access-credentials

# External Secrets Operator ExternalSecrets — two entries so `helm template`
# exercises the map-iteration path (data vs. dataFrom).
externalSecrets:
  app-secret:
    refreshInterval: 1h
    secretStoreRef:
      name: app-secretstore
      kind: SecretStore
    target:
      name: app-secret
      creationPolicy: Owner
    data:
      - secretKey: username
        remoteRef:
          key: my-secret
          property: username
      - secretKey: password
        remoteRef:
          key: my-secret
          property: password
  app-secret-bulk:
    secretStoreRef:
      name: app-secretstore
      kind: SecretStore
    dataFrom:
      - extract:
          key: my-other-secret

# =============================================================================
# STORAGE
# =============================================================================

# Volumes
volumes: []
# - name: foo
#   secret:
#     secretName: mysecret
#     optional: false

# Volume mounts
volumeMounts: []
# - name: foo
#   mountPath: "/etc/foo"
#   readOnly: true

# =============================================================================
# SCHEDULING
# =============================================================================

# Node selection
nodeSelector: {}

# Tolerations
tolerations: []

# Pod affinity and anti-affinity
affinity: {}

# =============================================================================
# JOBS
# =============================================================================

# Pre-install/pre-upgrade hook Job — enabled so `helm template` renders it.
jobs:
  - name: migrate
    enabled: true
    waitForIt: true
    command: ["/bin/sh", "-c"]
    args: ["echo running migrations"]
    restartPolicy: OnFailure
    backoffLimit: 6
    envVars:
      - name: JOB_MODE
        value: migrate

# =============================================================================
# SIDECARS
# =============================================================================

# Sidecar container — enabled so `helm template` renders the extra container,
# its Service port, and its appSettings Secret.
sidecars:
  - name: proxy
    enabled: true
    image:
      repository: alpine
      pullPolicy: IfNotPresent
      tag: "1.0.0"
    service:
      port: 8081
      targetPort: 8080
      targetScheme: HTTP
    appSettings:
      proxySetting: "proxyValue"

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

helmFrameworkSettings:
  configPath: "/app"
  configFileName: "appsettings.Production.json"

# Application settings and environment variables
appSettings:
  testSetting: "testValue"
  test1:
    test2: true
envVars:
  - name: foo
    value: bar
  - name: key
    value: value
envVarsFromSecret:
  secretKey: secretValue
```

## templates/deployment.yaml

```yaml
{{ include "helm-framework.deployment.global" . }}
```
