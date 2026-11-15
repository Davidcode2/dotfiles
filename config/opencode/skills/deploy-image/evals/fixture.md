# Isolated deployment evaluation environment

Use only these facts. No live discovery or actual deployment is permitted. Example proposed resources may be placed under `outputs/app-of-apps/` and `outputs/infra/`. Label unverified release digests and live status honestly. Don't fabricate a complete copy of the repositories; give precise patch snippets for existing files if necessary.

## Repository and cluster

- app-of-apps root watches root resource YAML, not recursively. Child apps watch their own directories. Canonical repo URL: https://github.com/davidcode2/app-of-apps. Auto-sync/prune/self-heal, namespace argocd for Applications. New root convention NAME-app.yaml.
- Real manifests and repositories must not be edited. Skill evaluation artifacts are the only allowed writes. Track no issues during evaluation.
- Target is three amd64 Linux K3s nodes using containerd, ingress-nginx, cert-manager, External Secrets Operator. Served ExternalSecret API is external-secrets.io/v1beta1, store aws-parameter-store (ClusterSecretStore).
- StorageClass local-path is installed/default; node-local provisioner rancher.io/local-path; WaitForFirstConsumer, reclaimPolicy Delete, no CSI snapshots or RWX. No database operator, storage replication, reload controller or backup system installed.
- No live access is available; only YAML parsing and offline relationship checking can be performed. Python and PyYAML are available. No schema validator is guaranteed.

## Existing network and DNS

- business-website owns jakob-lingel.dev `/` and www.jakob-lingel.dev `/` in namespace business-website; TLS Secret business-website-tls in that namespace contains a valid certificate for those two hosts, managed by its Ingress. The installed ingress-nginx combines compatible rules on shared hostnames and uses this certificate for the apex SNI hostname.
- hello-demo owns Prefix `/demo/gkv` for jakob-lingel.dev in namespace hello-demo; no TLS block of its own. No other /demo paths exist.
- letsencrypt-prod is a ClusterIssuer using HTTP-01 class nginx. Public HTTP-01 is possible once DNS is configured. No wildcard DNS or wildcard certificates.
- infra/terraform/global/dns/jakob-lingel.dev.tf manages DigitalOcean records. Apex uses digitalocean_domain.jakob-lingel-dev.name and A value 203.0.113.10 (TEST FIXTURE ONLY); it is the intended ingress. Existing subdomains use CNAME value "${digitalocean_domain.jakob-lingel-dev.name}.". reports and notes records are absent. Preserve existing records.
- Infra policy: agents must not execute any Terraform commands. Existing CI validates and applies DNS/parameter changes after the normal authorized review/merge flow. IAM bootstrap can require the user, but resource addresses are not supplied and must not be invented.

## Secrets

- The user has already provisioned a valid GHCR read-only credential as a SecureString at /shared/ghcr/dockerconfigjson. Its value is a complete Docker auth JSON with auths.ghcr.io. ESO IAM already permits this exact path. No need for new IAM or parameter resources for report-viewer. No pull Secrets yet exist in new app namespaces.
- An Argo GitHub App repo credential exists in argocd. It is not a container registry credential.
- field-notes database SecureStrings exist and ESO IAM can read them: /field-notes/db/username, /field-notes/db/password, /field-notes/db/name. Map to database and application env as documented below. Don't output their secret values.

## Image runtime contracts (assume documented, no remote lookups)

### nginxdemos/hello:plain-text
- Public Docker Hub image supports linux/amd64; listens on 0.0.0.0:80, serves text at arbitrary paths including /demo/scratch-hello. No assets, redirects, secrets or persistence. Root master process is required by this supplied image contract. GET / is a suitable direct Pod probe. Mutable tag; digest is not supplied.

### ghcr.io/davidcode2/report-viewer:1.4.2
- Private package; the existing /shared/ghcr/dockerconfigjson credential has access. linux/amd64, UID/GID 10001, listens on 0.0.0.0:8080. Stateless, no database. Env PUBLIC_URL=https://reports.jakob-lingel.dev. GET /ready and GET /live are respective probe paths. /tmp must be writable. Otherwise supports read-only root and dropped capabilities. Source application and Docker build are already done.

### ghcr.io/davidcode2/field-notes:2.3.0
- Public GHCR linux/amd64. UID/GID 10001. Listens on 0.0.0.0:8080. Env PUBLIC_URL=https://notes.jakob-lingel.dev, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, UPLOAD_DIR=/app/uploads. No build step or source edits needed.
- GET /ready requires completed migrations and DB connectivity. GET /live checks only process health; startup can take 90 seconds. No API credentials required for probes. /tmp writable; uploads require writable UID/GID 10001 storage.
- One app instance only: upload write coordination is not safe between instances. Use no overlapping app writers during rollout.
- Required schema migration: same app image, command ["/app/bin/field-notes", "migrate"], same DB env; exits 0 on success; idempotent and supports migration locking. Needs a reachable initialized database. Never runs automatically in server startup. It does not require uploads. Migration rollback is not guaranteed.
- PostgreSQL 16 official image postgres:16-alpine, env POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB; app DB_USER/DB_PASSWORD/DB_NAME must map to same secret data. Set PGDATA=/var/lib/postgresql/data/pgdata inside mounted /var/lib/postgresql/data. Initialization env affects only an empty data directory. One instance, no replication. Image may require root initialization before dropping privileges; don't force UID 10001 for this container.
- The user wants retained uploads and database at uninstall, not retained running compute. Backups should survive node loss; no destination, bucket credentials, schedule, retention duration or recovery objectives have yet been chosen. Document the missing decisions and a workable design; don't claim backup jobs are operational. No backup container image/version is prescribed.
