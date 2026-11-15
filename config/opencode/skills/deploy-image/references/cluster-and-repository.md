# Cluster and repository discovery

## Starting map (observed in repository on 2026-10-17)

These are discovery hints, not a live inventory. Re-read current files on each deployment.

- GitOps: `/home/jakob/documents/code/app-of-apps`.
- Infrastructure: `/home/jakob/documents/code/infra`.
- Root: `app-of-apps.yml`, Application `main-gitops-app`, path `.`, automated prune/self-heal.
- Canonical Git URL: `https://github.com/davidcode2/app-of-apps`. Use consistent lowercase URL matching ArgoCD repository credentials; don't infer credential failures solely from casing in an old manifest.
- App definition: `<name>-app.yaml`; resources: `<name>/`.
- Existing `hello-demo.yaml` is a naming exception, not the new-file convention.
- Intended cluster: three-node Hetzner K3s; discover actual node platform/runtime and capacity.
- Ingress: `ingress-nginx-app.yaml`; `traefik-app.yaml` is commented out. Do not choose a controller based merely on directory presence.
- `cluster-issuer/cert-manager-cluster-issuer.yaml`: `letsencrypt-prod` uses HTTP-01 with class nginx.
- `external-secrets/aws-secret-store.yaml`: ClusterSecretStore `aws-parameter-store`, AWS SSM eu-central-1. Repo examples use `external-secrets.io/v1beta1`; discover served versions rather than blindly using this or latest upstream v1.
- DNS: `infra/terraform/global/dns/jakob-lingel.dev.tf`, DigitalOcean records. Determine current ingress address instead of copying the hardcoded IP from an old example.

## Useful examples and limitations

| Example | Learn from it | Don't assume |
|---|---|---|
| `hello-demo/` | public image, probes/resources, `/demo/gkv` | arbitrary apps support prefixes; it declares no TLS of its own |
| `business-website/` | apex hostname `/` and TLS owner | route is unoccupied or safe to replace |
| `schreinerei-app/` | non-root versioned GHCR web image | all images support this security context/port |
| `schreinerei/` | Postgres, PVC, Recreate, secrets | a database Deployment is HA |
| `teachme/` | API prefix rewrite and startup probe | old annotations/health endpoints apply universally |
| `jakob-lingel/...personal-ingress.yaml` | oauth2-proxy protected path | a namespace itself isolates network traffic |
| `paperless-ngx/` | multi-component app | directory existence proves active deployment |

Read tracked relevant resources, not `backup/`, `.worktrees/` copies or files named like raw credentials. Local untracked work is not a source template to overwrite.

## Targeted read-only live discovery

Run only with an established intended context; use bounded timeouts. Missing tooling/access is a reportable limitation, not permission to provision infrastructure.

```bash
kubectl config current-context
kubectl --request-timeout=15s get nodes -o wide
kubectl --request-timeout=15s get ingressclass
kubectl --request-timeout=15s get svc -n ingress-nginx
kubectl --request-timeout=15s get storageclass
kubectl --request-timeout=15s get applications -n argocd
kubectl --request-timeout=15s get ingress -A
kubectl --request-timeout=15s get crd externalsecrets.external-secrets.io -o jsonpath='{.spec.versions[*].name}'
```

Inspect PV details, ServiceAccounts and secret **metadata/type** only when relevant. Nodes' architecture labels and `.status.nodeInfo.containerRuntimeVersion` inform image compatibility/import decisions. Storage class provisioner, binding mode, expansion and reclaim policy inform persistence choices.

## Application skeleton

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: APP_NAME
  namespace: argocd
  # Choose cascading-deletion finalizer only after resolving retention/ownership.
spec:
  project: default
  source:
    repoURL: https://github.com/davidcode2/app-of-apps
    targetRevision: HEAD
    path: APP_NAME
  destination:
    server: https://kubernetes.default.svc
    namespace: APP_NAME
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Replace placeholders before delivery. An explicit Namespace manifest is useful for labels or deliberate ownership but isn't required just to create one. Avoid shared namespaces for unrelated apps; deletion ownership becomes ambiguous.

An Application finalizer makes removing the child Application cascade to its managed resources. Without it, removing the Application can orphan resources. Neither behavior should be accidental. See the persistence reference for retained-data teardown.
