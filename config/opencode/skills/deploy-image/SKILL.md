---
name: deploy-image
description: Deploy existing container images to Jakob's K3s cluster through the app-of-apps GitOps repository, including public registries, public/private GHCR, local images, demo paths, new domains/subdomains, databases, persistent volumes, secrets, updates, rollback and teardown. Use whenever asked to run an image, spin up a demo or testing service, deploy a tool, or troubleshoot its deployment in app-of-apps. Includes narrowly scoped infra changes for DNS and secret prerequisites. Starts with an existing image; application creation, Dockerfile authoring and build/CI setup belong to other workflows.
---

# Deploy an existing image

Turn an existing image into a reproducible, verified GitOps deployment. Keep simple deployments quick; investigate the consequential details instead of blindly copying an existing manifest.

## User conventions

- Small experiments and demos: prefer `https://jakob-lingel.dev/demo/<name>`. Check subpath compatibility before choosing this route. If the image cannot work there, explain the reason and resolve a subdomain with the user.
- Real tools and projects: use a dedicated hostname, either a new subdomain or domain. Ask for the hostname if not supplied; do not invent domain ownership.
- Support databases and persistent applications fully, including their data lifecycle.
- Make narrowly scoped changes in `~/documents/code/infra` when DNS or secret prerequisites require them. Read its instructions first. Its current policy prohibits agents from running **any Terraform commands**, including fmt, init, plan and apply; use existing CI and give the user exact manual steps when necessary.
- Explain technical decisions when asked using evidence, tradeoffs and alternatives. Offer concise decision rationales, not a long unsolicited Kubernetes tutorial.

## Read the right reference

Read [cluster-and-repository.md](references/cluster-and-repository.md) first. Then load only relevant references:

| Need | Reference |
|---|---|
| Image requirements, GHCR credentials, local import | [images-and-registries.md](references/images-and-registries.md) |
| Demo path, host conflict, DNS, HTTPS, protocols | [networking-dns-and-tls.md](references/networking-dns-and-tls.md) |
| Environment, ExternalSecrets, SSM/IAM, runtime security | [configuration-and-secrets.md](references/configuration-and-secrets.md) |
| Any database, uploads, SQLite or other persistent state | [databases-and-persistence.md](references/databases-and-persistence.md) |
| Probes, validation, verification, failures, updates/removal | [verification-and-troubleshooting.md](references/verification-and-troubleshooting.md) |

## 1. Discover before choosing

1. Read applicable `AGENTS.md` files in every directory to be edited; inspect Git status and preserve user work. Use the repository's bd tracking, not a second issue system.
2. Identify the requested mode: discussion/plan, generate-only, deploy, update, diagnose or remove. Respect boundaries such as “don't push.” Follow the active harness's Git authorization rules; a deployment request does not override a requirement for explicit commit/push authorization.
3. Inspect the root ArgoCD app, nearby examples and relevant live capabilities when access is available. Distinguish **repository intent** from **observed cluster state**. Do not guess a kubeconfig or switch contexts silently.
4. Establish the image reference, public/private visibility, supported platform, port/protocol, command, environment, base URL/path support, writable directories and startup behavior. Use upstream documentation and image metadata; `EXPOSE` alone is not proof of a listener or health endpoint.
5. Check the host/path inventory, existing certificate owner, registry credential mechanism, storage classes and dependencies pertinent to this app. Avoid broad Secret dumps, arbitrary credential-file reads, or printing secret values.
6. Ask only for consequential unresolved inputs: hostname for a tool; missing required configuration; persistence size/retention; access to a private image; or an incompatible demo path. Continue independent work while blocked. Never fabricate application-specific env names, migration commands, UIDs, ports or endpoints.

Do not require AWS, Terraform, gh, or an application repository for a public image that needs none of them. Lack of cluster access permits generation and offline validation, not a claim that deployment succeeded.

## 2. Resolve a deployment contract

Summarize briefly, filling from evidence and defaults rather than presenting a questionnaire:

| Field | Resolve |
|---|---|
| Identity | app name, namespace, image tag/digest, architecture, pull authentication |
| Workload | Deployment / StatefulSet / Job / CronJob / DaemonSet, replicas and rollout |
| Runtime | ports, command/args, config/secret inputs, filesystem permissions |
| Exposure | internal / authenticated / public; hostname and path; prefix handling; TLS owner |
| Health/capacity | readiness/startup/liveness behavior; initial CPU/memory requests and limits |
| State | database, uploads, PVC storage class/size/access mode, backups and retention |
| Prerequisites | DNS, SSM/IAM, credentials, migration, controller/CRD availability |

For an uncomplicated demo, default to one replica, a dedicated namespace, ClusterIP Service, and the demo path if compatible. Resources are initial estimates, not guarantees. Use a Deployment for stateless HTTP apps; create no Service/Ingress for a worker that needs neither. Avoid creating SSM parameters, databases or persistent volumes unnecessarily.

Prefer immutable image digests or versioned tags; don't invent a digest. Keep an explicitly supplied mutable image when requested and explain its reproducibility limits.

## 3. Generate a coherent GitOps change

- Add root `<name>-app.yaml` and `<name>/` manifests using this repo's patterns and lowercase canonical Git URL. Root YAML is deployed by ArgoCD: keep notes, example manifests and non-resource YAML out of its watched paths.
- Use one clear owner per resource. Match namespace, Deployment selectors/Pod labels, Service selectors/targetPort and Ingress backends. Preserve immutable selectors when updating existing workloads.
- Add configuration, secret references, PVCs, dependent workloads and migration jobs as needed. A reference to a nonexistent Secret is not a complete deployment; either provision its source or explicitly identify the external blocker.
- Use image-compatible security settings; never solve every image by forcing a guessed non-root UID, read-only root filesystem, or writable root. Prefer least privilege where supported.
- Sequence dependencies within an Application using Sync waves only when needed. Namespaces/secrets/PVCs precede workloads; database and migration precede app. Wait for real readiness, not only object creation. A `PreSync` Job cannot use newly created normal-Sync prerequisites. Waves in separate Applications are not a general dependency guarantee.
- Scope infra edits to the app's records/parameters/access paths. Do not replace DNS zones, copy unrelated TXT/MX records, widen IAM broadly, change controllers, or bootstrap a new application repository.
- Set a deliberate retention policy before enabling cascading removal of persistent resources. A Namespace deletion can defeat PVC-level pruning protection; read the persistence reference before choosing finalizers.
- Update repository structure documentation when applicable instructions require it.

## 4. Validate, deliver, verify

Read [verification-and-troubleshooting.md](references/verification-and-troubleshooting.md) before completion.

Validate generated artifacts and resource relationships, then follow the authorized Git workflow. Keep infra prerequisite changes and app manifests separately reviewable. If authorization or external prerequisites block deployment, report exactly what is prepared and what still needs to happen; do not call generated YAML “deployed.”

After reconciliation verify the expected Git revision, ArgoCD sync/health, rollout, ready EndpointSlices, required Secret/PVC readiness and the actual application response. Verify hostname resolution and TLS separately. A redirect or authenticated response may be correct; HTTP 200 alone is neither required nor sufficient.

Finish with the URL/access method, changed paths, important choices, verification evidence, unresolved prerequisites and data-retention implications. Keep details proportionate. When explaining, use: **choice → evidence → consequence → when an alternative is better**.

## Examples of intent

- “Run this public image as a demo” → inspect runtime and subpath support; reuse the existing hostname/TLS owner; no automatic new DNS or CI.
- “Deploy my private GHCR tool at notes.jakob-lingel.dev” → confirm package access; reconcile a pull Secret in the workload namespace; add narrowly scoped DNS and TLS.
- “I only have this image in Docker locally” → explain registry publication versus explicit node-runtime import; don't pretend the remote cluster can access the laptop image store.
- “Run this with PostgreSQL and persistent uploads” → provision/configure both state stores, secrets and migrations; choose safe rollout, backup and deletion behavior.
- “Remove this demo but keep its data” → inspect finalizers, namespace ownership and volume reclaim policy before changing Git; preserve the requested state.
