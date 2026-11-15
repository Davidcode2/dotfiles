# Validation, health and lifecycle

## Probes and startup

Readiness decides traffic eligibility; liveness decides restart; startup gates the other probes for slow initialization. Choose paths/commands documented for this image, not `/health` by habit. Kubernetes probes hit the Pod directly and don't pass through public Ingress rewrites/auth.

Set startup budget from expected initialization; use readiness for whether this instance can serve. Avoid liveness checks that restart every app instance during a shared database outage. TCP readiness only proves a listener; database tools such as `pg_isready` do not prove app credentials, migrations or full query readiness. Don't probe an endpoint that is absent or requires credentials you haven't handled.

Use graceful termination, sensible rollout deadlines and bounded jobs. Jobs/CronJobs need appropriate restart/concurrency policies, not HTTP probes by default. Resource settings should accommodate startup/migration peaks as well as steady state.

## Before pushing

1. Parse YAML, including multiple documents; check kind/apiVersion/name/namespace. Run installed schema tools (e.g. kubeconform) against the target version, and report skipped/missing CRD schemas honestly.
2. Check selector/Pod-label/Service relationships, target ports, ingress backend namespace, host/path overlaps, TLS host ownership, Secret names/keys, PVC mounts, image pull references and placeholder resolution.
3. Render Helm/Kustomize if used; don't treat a valid template as a valid rendered resource. Keep plain manifests for simple apps unless repo patterns justify another format.
4. Where access permits, `kubectl apply --dry-run=server -f PATH` validates without persistence; client dry-run has weaker guarantees and may still need API discovery. A missing new namespace/CRD can block dry-run before Argo bootstrap; report this separately. Never replace validation with a real apply.
5. Inspect the diff for unintended files, secrets and immutable-field changes. Inspect Git status/diff/log before any authorized commit; stage only intended paths. Follow the active harness/repo Git rules and bd tracking. Don't bypass hooks or force-push.

Never run Terraform locally under current infra instructions. Use its CI quality gates, and distinguish pending CI validation from completed local checks.

## Verify deployment in layers

Use the correct context and bounded commands. Examples with resolved names:

```bash
kubectl --request-timeout=15s get application APP_NAME -n argocd
kubectl --request-timeout=15s rollout status deployment/APP_NAME -n APP_NAME --timeout=120s
kubectl --request-timeout=15s get pods,svc,endpointslices -n APP_NAME
kubectl --request-timeout=15s get externalsecret,pvc -n APP_NAME
kubectl --request-timeout=15s get certificate -n APP_NAME
dig HOSTNAME A
dig HOSTNAME AAAA
curl --max-time 20 -sS -D - https://HOSTNAME/PATH
```

Only query relevant kinds/resources. Use StatefulSet or Job completion status when appropriate. Inspect Application conditions, sync revision and operation result: Healthy/Synced at an older revision is not verification of the current change. Check the expected image and container imageID when reproducibility matters. Require ready endpoints; Running Pods alone aren't enough.

Validate application-specific expected content/status, deep links/assets for subpaths, redirects/auth behavior, valid TLS hostname/chain and DNS pointing at the intended endpoint. `curl -k` is not TLS verification. `curl --resolve HOST:443:IP` can test correct SNI/Host before DNS propagates, but does not prove public DNS is correct. Port-forward tests isolate app/service functionality but don't prove public routing.

For stateful apps additionally verify database connectivity/migration success, PVC binding, filesystem ownership, and the defined backup mechanism. A persistence restart/restore test is a stateful operation: use an approved test environment/procedure, not an unrequested disruption to live data.

If blocked, state which layer was verified and the specific remaining dependency. Do not equate file generation with deployment, or Argo object existence with working application behavior.

## Diagnose by evidence

| Symptom | Investigate |
|---|---|
| Argo comparison/sync error | repo access, revision/path, invalid API/CRD, admission, immutable selector, resource ownership |
| ImagePullBackOff | exact image/tag, public visibility, platform, registry reachability, Secret type/namespace, token expiration/package permission |
| Pending | requests/capacity, taints/affinity, PVC topology/binding, quota, WaitForFirstConsumer ordering |
| CrashLoopBackOff | bounded current/previous logs, exit code, OOMKilled, missing inputs, command, permissions, startup/liveness budget |
| Service has no endpoints | selectors, readiness, target namespace and ports |
| Ingress 404/502/503 | host/path/controller, rewrite, ready endpoints, listener bind address, backend protocol |
| TLS issuance failure | DNS A/AAAA/CAA, port 80, ingress class, HTTP-01 challenges, existing certificate owner |
| Assets/redirects broken | public/base URL, prefix handling, cookies, callbacks; rewrite isn't a universal fix |
| Multi-Attach/data unavailable | rollout overlap, volume node topology, detach timing, storage failure; don't bypass fencing |
| Secret updated but app unchanged | env captured at startup, subPath mounts, reload support, credential rotation inside database |

Useful read-only evidence: `kubectl describe pod`, namespace events, `kubectl logs --tail=100`, `kubectl logs --previous --tail=100`, ExternalSecret conditions, Certificate/Order/Challenge status. Logs can contain secrets; redact before sharing. Escalate diagnostics narrowly instead of dumping all cluster resources.

## Updates, rollback and removal

Update Git image/config with reproducible references and preserve immutable selectors. Reconcile automatically rather than using `kubectl set image`, patch/apply/delete or imperative rollout restart as the normal path. Reverting Git restores declarative state; imperative Argo rollback under auto-sync may be overridden. Confirm database/schema compatibility before rollback.

Remove exposure/compute and resolve retained state through Git, respecting finalizers and namespace deletion. Read the persistence reference even for a seemingly simple app if any claim exists. Verify workloads stopped and retained data still exists, then remove exclusively owned DNS/secrets if requested. Shared domain certificates and unrelated apps remain under their existing owner.
