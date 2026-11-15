# Runtime configuration and secrets

## Configuration contract

Use actual image documentation for env names, formats and required inputs. Distinguish public origin/base path, internal service URLs, database credentials and immutable build-time settings. Runtime env cannot necessarily alter URLs compiled into a frontend image.

Use ConfigMaps for non-sensitive configuration and ExternalSecrets/Secret references for credentials. Mount files if required by the application. `envFrom` imports keys as written; it does not translate `password` to `DB_PASSWORD`. Prefer explicit mappings where names differ. Quote env strings and avoid shell expansion assumptions in `command`/`args` (Kubernetes does not implicitly execute a shell).

SSM → ExternalSecret → namespaced Secret → workload is the established path. Inspect existing source paths and key mappings. The current ClusterSecretStore is `aws-parameter-store`. Discover served CRD versions before writing API syntax. A Secret reference must match its actual namespace, target name and keys.

Secret/config updates injected through environment variables require Pod replacement. Projected files normally update eventually, but `subPath` mounts do not receive automatic updates; apps may also need reload/restart. Use an existing reloader only if installed, otherwise a declared Pod-template configuration version/checksum updated through Git. Do not hash plaintext secrets into tracked files.

## Scope infrastructure work to real prerequisites

Inspect `infra/terraform/locals.tf`, `projects/` SSM modules, IAM policies and applicable instructions rather than copying old targeted commands. Existing secret access may already cover the requested path. New prefixes can require both CI-management permissions and ESO read permissions.

Create only parameters the app actually needs. Match resource definitions, SSM path, ESO mapping and application env exactly. Do not create dummy secrets for a secretless demo or leave dummy credentials presented as usable. SSM parameters managed with dummy initial values need the real values set by the approved secret procedure; verify that Terraform lifecycle settings won't overwrite them later.

Agents may edit narrowly scoped HCL but may not run Terraform commands under current infra instructions. CI handles routine DNS/parameter resources. For IAM bootstrap that CI cannot perform, give the user exact commands referring to verified resource addresses, explain ordering, and report the prerequisite as pending until verified. Avoid unnecessary privileged operations or invented IAM resource addresses.

Never commit plaintext/base64 secrets, private keys, real passwords in examples, Docker auth JSON, generated credential files or state. Don't ask the user to paste secrets into chat. Avoid `aws ssm get-parameter --with-decryption` and broad Secret YAML output during discovery. Verify metadata, status and key names instead. Creating a source secret or rotating database credentials is a distinct state change; don't rotate existing credentials just because redeploying.

## Image-compatible runtime security

- Prefer `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`, dropping unneeded capabilities and `automountServiceAccountToken: false` if the process does not use the Kubernetes API.
- Set `runAsNonRoot`, UID/GID, `fsGroup` and read-only root filesystem only after confirming compatibility. Some official images initialize as root then drop privileges; blocking their entrypoint can break initialization.
- Provide writable paths through appropriately owned PVCs or `emptyDir` for caches/tmp; read-only root is not a replacement for understanding writes.
- Avoid privileged Pods, hostPath, hostNetwork and broad RBAC as convenience defaults. When the image genuinely requires them, identify why and whether it fits the cluster.
- Resource requests drive scheduling; CPU limits throttle, memory limits can OOM-kill. Select initial values per app, include migration/init/sidecar peaks, then measure. Do not apply the demo's 256Mi memory limit to PostgreSQL or a JVM blindly.
- Use graceful SIGTERM behavior and sufficient termination grace time. A `preStop` hook consumes that same grace period.

Sources:
- https://external-secrets.io/latest/provider/aws-parameter-store/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
