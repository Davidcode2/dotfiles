---
name: deploy-app
description: Guide for deploying a new application to the Kubernetes cluster using GitOps
---

## Overview

This skill automates the end-to-end deployment of a new application while minimizing human intervention. Only two manual steps are required:
1. Running `terraform apply` to update IAM permissions
2. Adding GitHub secrets (APP_ID, APP_PRIVATE_KEY) to the application repository

Everything else is automated through code generation and GitHub Actions.

## Prerequisites

- `gh` CLI installed and authenticated
- Write access to GitHub repositories
- Git configured with user name and email

**Note on Documentation:** Use the `find-docs` skill to search for the latest information on ArgoCD, External Secrets Operator, cert-manager, or other tools if you encounter unfamiliar patterns or need up-to-date configuration syntax.

## Pre-Flight Validation

Run these checks before starting deployment to catch issues early:

### Check GitHub CLI Authentication
```bash
gh auth status
# Should show: "Logged in to github.com as <username>"
# If not logged in: gh auth login
```

### Check AWS Credentials
```bash
aws sts get-caller-identity
# Should return your AWS account ID and user ARN
# If not configured: aws configure
```

### Check Kubernetes Access
```bash
kubectl get nodes
# Should show cluster nodes
# If not connected: export KUBECONFIG=~/documents/code/infra/kubeconfig-<ip>.yaml
```

### Check Terraform State Access
```bash
cd ~/documents/code/infra/terraform
terraform init
# Should complete without errors
```

### Verify Repository Permissions
```bash
gh repo view Davidcode2/app-of-apps --json name
# Should show repo details
# If permission denied, ensure you have write access to the Davidcode2 organization
```

### Verify Required Tools
```bash
# Check all tools are installed
gh --version
kubectl version --client
terraform -version
aws --version
```

If any check fails, resolve the issue before proceeding.

## Domain Configuration

**Default Domain Behavior:**
- If the user does NOT specify a custom domain, use: **`<APP_NAME>.jakob-lingel.dev`**
  - Example: App named "blog-site" → domain is `blog-site.jakob-lingel.dev`
- If the user explicitly provides a domain, use that instead

**Creating DNS records:**
When using the default domain, create a CNAME record:
```bash
# In terraform/global/dns/jakob-lingel.dev.tf, add:
resource "digitalocean_record" "<APP_NAME>_cname" {
  domain = digitalocean_domain.jakob-lingel-dev.id
  type   = "CNAME"
  name   = "<APP_NAME>"
  value  = "@"
}
```

Replace `<DOMAIN>` with the actual domain throughout all configuration files.

## Phase 1: Application Repository Setup

### Step 1.1: Create or Verify Repository

Check if application repository exists:

```bash
gh repo view Davidcode2/<APP_NAME> --json name
```

If repo doesn't exist, create it:

```bash
gh repo create Davidcode2/<APP_NAME> --public --confirm
```

### Step 1.2: Initialize Repository Structure

Clone and setup the application repository:

```bash
cd ~/documents/code
gh repo clone Davidcode2/<APP_NAME>
cd <APP_NAME>
```

Create directory structure based on application type:

**For Static Sites (like mimis-kreativstudio, teachme):**
```
.
├── src/
├── public/
├── package.json
├── dockerfile.optimized
├── nginx.conf
└── .github/
    └── workflows/
        ├── main.yml
        └── build-and-push.yml
```

**For Full-Stack Apps (like immoly):**
```
.
├── backend/
├── frontend/
├── docker-compose.yml
├── dockerfile.backend
├── dockerfile.frontend
└── .github/
    └── workflows/
        └── main.yml
```

**For Strapi CMS (like joy_alemazung):**
```
.
├── src/
├── config/
├── database/
├── package.json
├── dockerfile
└── .github/
    └── workflows/
        └── main.yml
```

### Step 1.3: Copy Templates from Reference Repos

**For static sites - copy from mimis-kreativstudio:**

```bash
# Copy workflow templates
cp ~/documents/code/mimis-kreativstudio/.github/workflows/main.yml .github/workflows/
cp ~/documents/code/mimis-kreativstudio/.github/workflows/build-and-push.yml .github/workflows/

# Copy Dockerfile and nginx config
cp ~/documents/code/mimis-kreativstudio/dockerfile.optimized dockerfile
cp ~/documents/code/mimis-kreativstudio/nginx.conf nginx.conf
```

**For Strapi CMS - copy from joy_alemazung:**

```bash
# Copy workflow templates
cp ~/documents/code/joy_alemazung/.github/workflows/main.yml .github/workflows/
cp ~/documents/code/joy_alemazung/.github/workflows/build-and-push.yml .github/workflows/

# Copy Dockerfile
cp ~/documents/code/joy_alemazung/dockerfile dockerfile
```

**For full-stack with database - copy from immoly:**

```bash
# Copy workflow templates
cp ~/documents/code/immoly/.github/workflows/main.yml .github/workflows/

# Copy Docker configs
cp ~/documents/code/immoly/dockerfile.backend dockerfile.backend
cp ~/documents/code/immoly/dockerfile.frontend dockerfile.frontend
```

### Step 1.4: Adapt Templates for New Application

Replace placeholders in copied files. Update all occurrences of:
- `<APP_NAME>` → actual application name (e.g., "my-new-app")
- `<DOMAIN>` → primary domain (see [Domain Configuration](#domain-configuration) above - use `<APP_NAME>.jakob-lingel.dev` if no custom domain specified)
- `<OWNER_LC>` → lowercase owner (e.g., "davidcode2")

Example sed commands:

```bash
# Update workflow files
sed -i "s/mimis-kreativstudio/<APP_NAME>/g" .github/workflows/*.yml
sed -i "s/mimis-kreativstudio.de/<DOMAIN>/g" .github/workflows/*.yml

# Update package.json if copied
sed -i "s/mimis-kreativstudio/<APP_NAME>/g" package.json
```

### Step 1.5: Initialize Application Code

Create minimal `package.json` for static sites:

```json
{
  "name": "<APP_NAME>",
  "version": "0.0.1",
  "description": "<APP_NAME> application",
  "scripts": {
    "build": "<build_command>"
  },
  "dependencies": {}
}
```

Commit and push initial structure:

```bash
git add .
git commit -m "feat: Initial application structure

- Add CI/CD workflows
- Add Dockerfile configuration
- Add package.json

Refs: bd-<task-id>"
git push -u origin main
```

## Phase 2: Infrastructure Configuration (SSM Parameters)

### Step 2.1: Add Application to Locals

Edit `~/documents/code/infra/terraform/locals.tf` and add the app to the `app_patterns` map:

```hcl
app_patterns = {
  # ... existing apps ...
  <APP_NAME> = "<APP_NAME>"
}
```

### Step 2.2: Create SSM Parameters as Code

Create SSM parameter definitions in `~/documents/code/infra/terraform/projects/ssm.tf`:

For static sites (minimal/no secrets):
```hcl
# <APP_NAME> application secrets
module "<APP_NAME>_secrets" {
  source = "./ssm_module"
  app_name = "<APP_NAME>"
  environment = "prod"
  
  parameters = {
    "api/key" = { description = "API key for <APP_NAME>" }
  }
}
```

For full-stack apps with database (like immoly):
```hcl
# <APP_NAME> database secrets
module "<APP_NAME>_db" {
  source = "./ssm_module"
  app_name = "<APP_NAME>"
  environment = "prod"
  
  parameters = {
    "db/host"     = { description = "Database host for <APP_NAME>" }
    "db/port"     = { description = "Database port" }
    "db/username" = { description = "Database username" }
    "db/password" = { description = "Database password" }
    "db/name"     = { description = "Database name" }
    "jwt/secret"  = { description = "JWT secret key" }
  }
}
```

For Strapi CMS (like joy_alemazung):
```hcl
# <APP_NAME> CMS secrets
module "<APP_NAME>_cms" {
  source = "./ssm_module"
  app_name = "<APP_NAME>"
  environment = "prod"
  
  parameters = {
    "db/host"       = { description = "Database host" }
    "db/port"       = { description = "Database port" }
    "db/username"   = { description = "Database username" }
    "db/password"   = { description = "Database password" }
    "db/name"       = { description = "Database name" }
    "app/keys"      = { description = "Strapi app keys" }
    "api/token/salt" = { description = "API token salt" }
    "admin/jwt/secret" = { description = "Admin JWT secret" }
    "transfer/token/salt" = { description = "Transfer token salt" }
  }
}
```

### Step 2.3: Commit Infrastructure Changes

```bash
cd ~/documents/code/infra
git add terraform/locals.tf terraform/projects/ssm.tf
git commit -m "feat: Add <APP_NAME> to infrastructure

- Add app pattern to locals.tf
- Create SSM parameter resources

Refs: bd-<task-id>"
git push
```

## Phase 3: Terraform Apply (HUMAN SUPERVISION REQUIRED)

⚠️ **STOP - Human intervention required**

The CI pipeline cannot modify its own IAM permissions. A human must run these commands locally:

```bash
cd ~/documents/code/infra/terraform

# Update CI role permissions
terraform apply -target=aws_iam_role_policy.terraform_ci_policy
terraform apply -target=aws_iam_role_policy.ci-policy
terraform apply -target=aws_iam_user_policy.external_secrets_ssm
```

After successful apply, the infra repo CI will automatically create the SSM parameters.

### Step 3.1: Set Real SSM Parameter Values

⚠️ **STOP - Human intervention required**

After parameters are created, set real values using AWS CLI. **For new secrets, generate secure values using openssl:**

```bash
# Generate secure random secrets (run these to create values)
# For API keys, JWT secrets, tokens:
openssl rand -base64 48

# For app keys (comma-separated pair):
echo "$(openssl rand -base64 48),$(openssl rand -base64 48)"

# For database passwords (32 chars, alphanumeric):
openssl rand -base64 24 | tr -d "=+/" | cut -c1-32
```

Then set the values using AWS CLI:

```bash
# Check parameter exists
aws ssm get-parameter --name "/<APP_NAME>/api/key"

# Set the actual value (replace with generated value from openssl commands above)
aws ssm put-parameter \
  --name "/<APP_NAME>/api/key" \
  --value "$(openssl rand -base64 48)" \
  --type SecureString \
  --overwrite

# For full-stack apps with database secrets:
# Generate and set a strong password:
aws ssm put-parameter --name "/<APP_NAME>/db/password" --value "$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-32)" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/db/username" --value "app_user" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/db/host" --value "postgres-service" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/db/name" --value "<APP_NAME>" --type SecureString --overwrite

# For Strapi CMS apps (use generated secrets):
aws ssm put-parameter --name "/<APP_NAME>/app/keys" --value "$(openssl rand -base64 48),$(openssl rand -base64 48)" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/api/token/salt" --value "$(openssl rand -base64 48)" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/admin/jwt/secret" --value "$(openssl rand -base64 48)" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/transfer/token/salt" --value "$(openssl rand -base64 48)" --type SecureString --overwrite
aws ssm put-parameter --name "/<APP_NAME>/jwt/secret" --value "$(openssl rand -base64 48)" --type SecureString --overwrite
```

**Security Note:** Always generate new secrets for each deployment. Never reuse secrets across applications or environments.

## Phase 4: GitOps Manifests (app-of-apps)

### Step 4.1: Create Application Directory Structure

Create directory in app-of-apps:

```bash
mkdir -p ~/documents/code/app-of-apps/<APP_NAME>
```

### Step 4.2: Create ArgoCD Application

Create `~/documents/code/app-of-apps/<APP_NAME>-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <APP_NAME>
  namespace: argocd
spec:
  project: default
  source:
    # IMPORTANT: Use lowercase owner in repoURL. GitHub App authentication
    # (gitops-read-access) is case-sensitive — a mixed-case owner like
    # "Davidcode2" will fail auth on private repos.
    repoURL: https://github.com/davidcode2/app-of-apps
    path: <APP_NAME>
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: <APP_NAME>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Step 4.3: Create Kubernetes Manifests

**For Static Sites:**

Create `~/documents/code/app-of-apps/<APP_NAME>/<APP_NAME>-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <APP_NAME>
  namespace: <APP_NAME>
spec:
  replicas: 2
  selector:
    matchLabels:
      app: <APP_NAME>
  template:
    metadata:
      labels:
        app: <APP_NAME>
    spec:
      containers:
      - name: <APP_NAME>
        image: ghcr.io/davidcode2/<APP_NAME>:0.0.1
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

Create `~/documents/code/app-of-apps/<APP_NAME>/<APP_NAME>-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: <APP_NAME>
  namespace: <APP_NAME>
spec:
  selector:
    app: <APP_NAME>
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

Create `~/documents/code/app-of-apps/<APP_NAME>/<APP_NAME>-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <APP_NAME>
  namespace: <APP_NAME>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - <DOMAIN>
    - www.<DOMAIN>
    secretName: <APP_NAME>-tls
  rules:
  - host: <DOMAIN>
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <APP_NAME>
            port:
              number: 80
  - host: www.<DOMAIN>
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <APP_NAME>
            port:
              number: 80
```

**CRITICAL: External Secrets Configuration for Database Apps**

When deploying apps with databases, you MUST create an ExternalSecret resource. This syncs AWS SSM parameters to Kubernetes secrets automatically.

Create `~/documents/code/app-of-apps/<APP_NAME>/<APP_NAME>-external-secret.yaml`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: <APP_NAME>-db-secret
  namespace: <APP_NAME>
spec:
  refreshInterval: 6h
  secretStoreRef:
    name: aws-parameter-store
    kind: ClusterSecretStore
  target:
    name: <APP_NAME>-db-secret
    creationPolicy: Owner
  data:
    - secretKey: host
      remoteRef:
        key: /<APP_NAME>/db/host
    - secretKey: port
      remoteRef:
        key: /<APP_NAME>/db/port
    - secretKey: username
      remoteRef:
        key: /<APP_NAME>/db/username
    - secretKey: password
      remoteRef:
        key: /<APP_NAME>/db/password
    - secretKey: dbname
      remoteRef:
        key: /<APP_NAME>/db/name
```

Update deployment to use secret:

```yaml
# In <APP_NAME>-deployment.yaml, add to container spec:
env:
- name: DATABASE_HOST
  valueFrom:
    secretKeyRef:
      name: <APP_NAME>-db-secret
      key: host
- name: DATABASE_PORT
  valueFrom:
    secretKeyRef:
      name: <APP_NAME>-db-secret
      key: port
# ... etc
```

**For Database Migration Job (Optional):**

Create `~/documents/code/app-of-apps/<APP_NAME>/<APP_NAME>-migration-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: <APP_NAME>-migration
  namespace: <APP_NAME>
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: ghcr.io/davidcode2/<APP_NAME>:0.0.1
        command: ["npm", "run", "migrate"]
        envFrom:
        - secretRef:
            name: <APP_NAME>-db-secret
```

### Step 4.4: Commit GitOps Changes

**IMPORTANT:** Make sure to add ALL generated files including external-secret.yaml:

```bash
cd ~/documents/code/app-of-apps

# Add all generated files
git add <APP_NAME>/ <APP_NAME>-app.yaml

# Verify external-secret is included (for database apps)
git status | grep external-secret || echo "WARNING: external-secret.yaml not found!"

git commit -m "feat: Add <APP_NAME> to GitOps

- Add ArgoCD application definition
- Add Kubernetes manifests (deployment, service, ingress)
- Add ExternalSecret for database credentials
- Add migration job (if applicable)

Refs: bd-<task-id>"
git push
```

**Verify ExternalSecret sync:**
After ArgoCD syncs, verify the secret was created:
```bash
kubectl get externalsecret -n <APP_NAME>
kubectl get secret <APP_NAME>-db-secret -n <APP_NAME>
```

## Phase 5: DNS Configuration

### Step 5.1: Determine DNS Strategy

**If using default domain (`<APP_NAME>.jakob-lingel.dev`):**
Skip to Step 5.2b - you'll add a CNAME record to the existing jakob-lingel.dev.tf file.

**If using a custom domain:**
Follow Step 5.2a below.

### Step 5.2a: Copy DNS Template for Custom Domain

Create DNS configuration by copying from an existing domain:

```bash
cd ~/documents/code/infra/terraform/global/dns
```

Copy from mimis-kreativstudio.de.tf:

```bash
cp mimis-kreativstudio.de.tf <DOMAIN>.tf
```

Adapt the configuration:

```hcl
# Replace all occurrences
sed -i "s/mimis-kreativstudio/<APP_NAME>/g" <DOMAIN>.tf
sed -i "s/mimis-kreativstudio.de/<DOMAIN>/g" <DOMAIN>.tf

# Update LoadBalancer IP if needed (copy from existing working domain)
# Check current LB IP from any working domain file
```

### Step 5.2b: Add CNAME for Default Domain

If using `<APP_NAME>.jakob-lingel.dev`, edit the existing file:

```bash
cd ~/documents/code/infra/terraform/global/dns
```

Add to `jakob-lingel.dev.tf`:

```hcl
# <APP_NAME> application CNAME
resource "digitalocean_record" "<APP_NAME>_cname" {
  domain = digitalocean_domain.jakob-lingel-dev.id
  type   = "CNAME"
  name   = "<APP_NAME>"
  value  = "@"
}
```

### Step 5.3: Commit and Apply DNS

```bash
cd ~/documents/code/infra
git add terraform/global/dns/<DOMAIN>.tf
git commit -m "feat: Add DNS for <APP_NAME>

- Add DNS records for <DOMAIN>
- Point to LoadBalancer

Refs: bd-<task-id>"
git push
```

The infra CI will automatically apply DNS changes.

## Phase 6: GitHub Secrets Configuration (HUMAN SUPERVISION REQUIRED)

⚠️ **STOP - Human intervention required**

Add GitHub secrets to the application repository using the GitHub CLI:

```bash
# Navigate to app repo
cd ~/documents/code/<APP_NAME>

# Set APP_ID (replace with actual GitHub App ID)
gh secret set APP_ID --body "<APP_ID_VALUE>"

# Set APP_PRIVATE_KEY from file (replace with actual path to private key)
gh secret set APP_PRIVATE_KEY < /path/to/private-key.pem

# Verify secrets were set
gh secret list
```

**Getting the values:**
- The GitHub App must already exist in your organization
- Find the APP_ID: `gh api /apps/<app-name> | jq -r '.id'`
- The private key file should have been downloaded when the GitHub App was created
- Contact your admin if you don't have access to these values

## Phase 7: Initial Deployment

### Step 7.1: Trigger Initial Build

Create a README or initial commit to trigger CI:

```bash
cd ~/documents/code/<APP_NAME>
echo "# <APP_NAME>" > README.md
git add README.md
git commit -m "docs: Add README

Refs: bd-<task-id>"
git push
```

### Step 7.2: Monitor CI Pipeline

Watch the GitHub Actions workflow:

```bash
gh workflow view main.yml --repo Davidcode2/<APP_NAME>
```

Wait for workflow to complete (version bump → build → push → deploy).

### Step 7.3: Verify ArgoCD Sync

Check ArgoCD application status:

```bash
kubectl get application <APP_NAME> -n argocd
```

Or use ArgoCD CLI:

```bash
argocd app get <APP_NAME>
```

Status should show "Healthy" and "Synced".

### Step 7.4: Verify Deployment

Check pods are running:

```bash
kubectl get pods -n <APP_NAME>
```

Test endpoint:

```bash
curl -I https://<DOMAIN>
```

Should return HTTP 200.

## Phase 8: Verification Checklist

After deployment completes, verify:

**Note:** If this is a German website or targets German users, use the `create-impressum` skill to generate a legally compliant impressum (legal notice) page. German law requires an impressum with specific information including business address, contact details, and responsible person. The impressum must be easily accessible from every page (typically linked in the footer).

- [ ] ArgoCD application shows "Healthy" and "Synced"
- [ ] Pods are running: `kubectl get pods -n <APP_NAME>`
- [ ] Service is accessible: `kubectl get svc -n <APP_NAME>`
- [ ] Ingress is configured: `kubectl get ingress -n <APP_NAME>`
- [ ] DNS resolves: `dig <DOMAIN>`
- [ ] TLS certificate is valid: `curl -v https://<DOMAIN>`
- [ ] CI/CD pipeline runs on push to main
- [ ] Application responds with HTTP 200

## Reference Projects

### Static Sites

**mimis-kreativstudio**
- Simple static site with nginx
- Location: `~/documents/code/mimis-kreativstudio/`
- GitOps: `~/documents/code/app-of-apps/mimis-kreativstudio/`

**teachme**
- Educational platform static site
- Location: `~/documents/code/teachme/`

### Full-Stack with Database

**immoly**
- Real estate calculation tool
- PostgreSQL database
- Database migrations
- Location: `~/documents/code/immoly/`
- GitOps: `~/documents/code/app-of-apps/immoly/`
- Includes: migration job, external secrets

### Strapi CMS

**joy_alemazung**
- Content management system
- Strapi backend
- Database integration
- Location: `~/documents/code/joy_alemazung/`

## Troubleshooting

### CI/CD Pipeline Fails

Check GitHub Actions logs:
```bash
gh run list --repo Davidcode2/<APP_NAME>
gh run view <run-id> --repo Davidcode2/<APP_NAME>
```

Common issues:
- Missing GitHub secrets (APP_ID, APP_PRIVATE_KEY)
- Dockerfile build errors
- Permission issues with GHCR

### ArgoCD Not Syncing

Force sync:
```bash
argocd app sync <APP_NAME>
```

Check for errors:
```bash
argocd app get <APP_NAME> -o yaml
```

### Pods Not Starting

Check pod status:
```bash
kubectl describe pod -n <APP_NAME> <pod-name>
kubectl logs -n <APP_NAME> <pod-name>
```

Common issues:
- Image pull errors (check GHCR permissions)
- Resource limits too low
- Missing environment variables/secrets

### DNS Not Resolving

Check DNS records:
```bash
dig <DOMAIN>
dig @ns1.digitalocean.com <DOMAIN>
```

Verify LoadBalancer IP is correct in Terraform.

## Cleanup

If deployment needs to be removed:

1. Delete ArgoCD application:
   ```bash
   argocd app delete <APP_NAME>
   ```

2. Remove manifests from app-of-apps:
   ```bash
   cd ~/documents/code/app-of-apps
   rm -rf <APP_NAME>/ <APP_NAME>-app.yaml
   git commit -am "Remove <APP_NAME> deployment"
   git push
   ```

3. Remove from Terraform (optional):
   - Remove from `locals.tf` app_patterns
   - Remove SSM module from `ssm.tf`
   - Remove DNS records
   - Commit and push (human must run terraform apply)

4. Remove GitHub repository (optional):
   ```bash
   gh repo delete Davidcode2/<APP_NAME> --confirm
   ```
